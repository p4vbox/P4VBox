/*
 *  This program is free software: you can redistribute it and/or modify
 *  it under the terms of the GNU General Public License as published by
 *  the Free Software Foundation, either version 3 of the License, or
 *  (at your option) any later version.
 */

#include <arpa/inet.h>
#include <linux/if_packet.h>
#include <stdio.h>
#include <string.h>
#include <stdlib.h>
#include <sys/ioctl.h>
#include <sys/socket.h>
#include <net/if.h>
#include <netinet/ether.h>

#define MY_DEST_MAC0	0x08
#define MY_DEST_MAC1	0x22
#define MY_DEST_MAC2	0x22
#define MY_DEST_MAC3	0x22
#define MY_DEST_MAC4	0x22
#define MY_DEST_MAC5	0x08

#define MY_SRC_MAC0	0x08
#define MY_SRC_MAC1	0x11
#define MY_SRC_MAC2	0x11
#define MY_SRC_MAC3	0x11
#define MY_SRC_MAC4	0x11
#define MY_SRC_MAC5	0x08

#define DEFAULT_IF	"eth0"
#define BUF_SIZ		256
#define SRC_IP "10.0.0.1"
#define DST_IP "10.0.0.2"

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


int main(int argc, char *argv[])
{
	int sockfd;
	struct ifreq if_idx;
	struct ifreq if_mac;
	int tx_len = 0;
	char sendbuf[BUF_SIZ];
	struct ether_header *eh = (struct ether_header *) sendbuf;
	struct ip *iph = (struct ip *) (sendbuf + sizeof(struct ether_header));
	struct sockaddr_ll socket_address;
	char ifName[IFNAMSIZ];

        tx_len = 0;
	/* Get interface name */
	if (argc > 1)
		strcpy(ifName, argv[1]);
	else
		strcpy(ifName, DEFAULT_IF);

	/* Open RAW socket to send on */
	if ((sockfd = socket(AF_PACKET, SOCK_RAW, IPPROTO_RAW)) == -1) {
	    perror("socket");
	}

	/* Get the index of the interface to send on */
	memset(&if_idx, 0, sizeof(struct ifreq));
	strncpy(if_idx.ifr_name, ifName, IFNAMSIZ-1);
	if (ioctl(sockfd, SIOCGIFINDEX, &if_idx) < 0)
	    perror("SIOCGIFINDEX");
	/* Get the MAC address of the interface to send on */
	// memset(&if_mac, 0, sizeof(struct ifreq));
	// strncpy(if_mac.ifr_name, ifName, IFNAMSIZ-1);
	// if (ioctl(sockfd, SIOCGIFHWADDR, &if_mac) < 0)
	   // perror("SIOCGIFHWADDR");

	/* Construct the Ethernet header */
	memset(sendbuf, 0, BUF_SIZ);
	/* Ethernet header */
	// eh->ether_shost[0] = ((uint8_t *)&if_mac.ifr_hwaddr.sa_data)[0];
	// eh->ether_shost[1] = ((uint8_t *)&if_mac.ifr_hwaddr.sa_data)[1];
	// eh->ether_shost[2] = ((uint8_t *)&if_mac.ifr_hwaddr.sa_data)[2];
	// eh->ether_shost[3] = ((uint8_t *)&if_mac.ifr_hwaddr.sa_data)[3];
	// eh->ether_shost[4] = ((uint8_t *)&if_mac.ifr_hwaddr.sa_data)[4];
	// eh->ether_shost[5] = ((uint8_t *)&if_mac.ifr_hwaddr.sa_data)[5];
	eh->ether_dhost[0] = MY_DEST_MAC0;
	eh->ether_dhost[1] = MY_DEST_MAC1;
	eh->ether_dhost[2] = MY_DEST_MAC2;
	eh->ether_dhost[3] = MY_DEST_MAC3;
	eh->ether_dhost[4] = MY_DEST_MAC4;
	eh->ether_dhost[5] = MY_DEST_MAC5;

        eh->ether_shost[0] = MY_SRC_MAC0;
	eh->ether_shost[1] = MY_SRC_MAC1;
	eh->ether_shost[2] = MY_SRC_MAC2;
	eh->ether_shost[3] = MY_SRC_MAC3;
	eh->ether_shost[4] = MY_SRC_MAC4;
	eh->ether_shost[5] = MY_SRC_MAC5;
	/* Ethertype field */
	eh->ether_type = htons(ETH_P_IP);
	tx_len += sizeof(struct ether_header);

	iph->ip_vhl = 69; /* Version and IHL */
	iph->ip_tos = 0x10;         /* Type Of Service (TOS) */
	iph->ip_len = htons(BUF_SIZ - sizeof(struct ether_header));       /* total length of the IP datagram */
	iph->ip_id = htons(0); /* identification */
	iph->ip_off = htons (IP_DF);  /* fragmentation flag */
	iph->ip_ttl = 255;          /* Time To Live (TTL) */
	iph->ip_p = IPPROTO_RAW; /* protocol used (TCP in this case) */
	iph->ip_sum = 0;          /* IP checksum */
	iph->ip_src.s_addr = inet_addr (SRC_IP);
	iph->ip_dst.s_addr = inet_addr (DST_IP);  /* destination address */

	tx_len += sizeof (struct ip);

	/* Packet data */
        for (; tx_len < BUF_SIZ; tx_len++)
          sendbuf[tx_len] = 'a';

	/* Index of the network device */
	socket_address.sll_ifindex = if_idx.ifr_ifindex;
	/* Address length*/
	socket_address.sll_halen = ETH_ALEN;
	/* Destination MAC */
	socket_address.sll_addr[0] = MY_DEST_MAC0;
	socket_address.sll_addr[1] = MY_DEST_MAC1;
	socket_address.sll_addr[2] = MY_DEST_MAC2;
	socket_address.sll_addr[3] = MY_DEST_MAC3;
	socket_address.sll_addr[4] = MY_DEST_MAC4;
	socket_address.sll_addr[5] = MY_DEST_MAC5;

	/* Send packet */
	for (int i = 0; ; i++)
          if (sendto(sockfd, sendbuf, tx_len, 0, (struct sockaddr*)&socket_address, sizeof(struct sockaddr_ll)) < 0)
	    printf("Send failed\n");

	return 0;
}
