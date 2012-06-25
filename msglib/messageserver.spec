--*-text-*--

A Messageing Service In Q

The objective of the message service is to simplify the interprocess
communication between many q processes across many hosts.  Instead of
maintaining links between all processes that need to exchange
messages, all processes just maintain a connection to the messaging
server.  The messaging server will offer the capability of routing
messages between nodes in the network.  This avoids the need for each
node in the network to perform its own connection and communication
management (e.g. dealing with connection setup and shutdown). The client
processes only have to maintain one connection to the messaging service.
This also allows the implementation of send or receive timeouts.

The base framework envisions one local messaging agent on each machine
and two remote messaging servers (a and b, for redundancy). It is
expected that the two remote messaging servers will be placed on
different hosts, potentially in different physical locations. A local
messaging agent is run on each host that runs client processes. The
client processes will connect only to the local agent, which is
responsible for routing messages locally between client processes. The
local agent will route all messages that cannot be delivered locally
to one of the messaging servers.  It is to be determined how the
messages will be distributed between the two servers, but the design
objective will be to allow the messaging system to remain functional
even when one of the messaging servers goes down.

It is clear that all messages between the clients, the agents and the
servers will be sent asynchronously. In the first versions of the
framework there will be no delivery guarantee (as it opens a whole can
of worms). In other words, the framework can loose messages and client
applications should take that into consideration.

Features that the framework is expected to provide:

* A pub/sub system that supports multiple publishers
* Remote function calls, i.e. the message causes an expression to be
  evaluated at the recipient process(es)
* Alias addresses: Nodes can register additional names under which they wish
  to receive messages
* Anycast groups: A message sent to an anycast group is delivered to one (and
  only one) of the nodes that have joined the anycast group.
* Erlang-style messaging, i.e. messages are buffered at the recipient process
  and only consumed when the client process asks for them; including the blocking
  receive call. Implementation note: This is envisaged to be implemented by doing
  a sync read on the local agent connection. If a timeout applies, the local agent
  is notified of the timeout and it will send the client process a message after
  the timer expires.

Implementation Notes

Each client must register at least one address under which it wants to
receive messages; its primary address. Clients may register additional
ones, including multicast or anycast groups. The primary address must
only be unique on the host that the client (and its local messaging
node) is running on.  Frequently the primary address will be the port
that the client is using, but it is not required that clients have a port
for receiving communications outside of the messaging service.

The messaging servers will take advantage of Q's features to avoid
the de-serialization and re-serialization of messages.

A local messaging node will maintain connections to all remote
forwarding nodes in the network. When forwarding a message with a
destination outside of the local node, it will randomly select one of
the available remote nodes to forward the message. A possible later
enhancement is the addition of some communication between the
forwarders and the local nodes so that better load balancing is
achieved.

If only for testing purposes, the notion of the local hostname of a
local server can be changed via the command-line.

The local messaging nodes will only maintain a routing table of their
own clients. They will register all addresses with the forwarding
nodes.  The forwarding nodes maintain global routing tables.
Initially, there will be two address classes, network-global addresses
and node-local addresses. Both are unicast addresses. Node-local
addresses (which are still globally visible) are essentially the
addresses of all clients of the node, prefixed with the name of the
node. Node-local addresses include the primary addresses of clients.

Nodes may register network-global addresses unicast addresses (future
versions may support anycast and multicast). A network-global unicast
address must be unique within the network. The registration request is
submitted by the local messaging service to all forwarders. Only if
all forwarders accept the registration, it is confirmed back to the
client.

When a client disconnects, the local messaging service will
de-register all the addresses of that client with the forwarders.  Any
message that has not been delivered is discarded when the respective
messaging service discovers that its destination address is currently
unreachable. No effort is made to support shared state protocols
between clients. In other words, if a client keeps sending messages to
an address, the message will be delivered when the address is known
(reachable) and discarded otherwise. As soon another client registers
the address subsequent messages from the sender are delivered to that
client. So in the case of a dialogue between two clients that implies
state changes between them and one of the partners is restarted, it
will start to receive messages from the surviving partner that could
be inconsistent with the protocol state it was restarted in. It is up
to the clients to deal with such failures.

Initially, the system will not provide any feedback to the sender of a
message. Potential enhancements include error notifications in case
of dropped messages or explicit delivery confirmations.

