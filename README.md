#ulib
# The Universal Libary MTP3 library

ulibmtp3 is a implementation of the SS7 MTP3 protocol as well as M3UA, M2PA
it makes extensive use of the universal library "ulib".
It works on Linux, FreeBSD and to some extent on MacOS (due to its lacking SCTP support, 
M2PA can not be implemented and M3UA can only be done over tcp)

Under Linux and FreeBSD, GNUStep is used as an underlying framework.
Under MacOS Foundation is used.



# Related #

ulibm4p3 is the base class of a family of libraries and applications .It gets used and extended by

* **ulib**     a universal library 
* **ulibsccp** a library implementing the SS7 SCCP protocol
* **ulibtcap** a library implementing the SS7 TCAP protocol
* **ulibgsmmap** a library implementing the SS7 GSM-MAP protocol
* **ulibsms**  a library implementing SMS encoding/decoding functions
* **ulibsmpp** a library to deal with the SMPP protocol
* **ulibdns** a library doing DNS functionality
* **schrittmacherclient** a library for applications to implement a hot/standby mechanism
* **schrittmacher** a system daemon dealing with applications in a hot/standby setup, making sure there is always one system hot and one is standby.
* **messagemover** a application implementing a SS7 GSM-SMSC (commercial)
* **estp** a application implementing a SS7 packet router (enhanced signaling transfer point) (commercial)
* **smsproxy** a application implementing a HLR and MSC for receiving SMS on SS7 (commercial)
* **gsm-api** a application implementing a SS7 API Server for all kinds of lookups. (commercial)

# Merged functionalities #

Release 6.0 (2026) merged in some functionality which where previously in separately libraries
* **ulibm2pa**   m2pa functions 
