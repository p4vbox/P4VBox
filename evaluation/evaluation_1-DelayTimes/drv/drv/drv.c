#include <linux/ktime.h>
#include <linux/kernel.h>
#include <linux/module.h>
#include <linux/skbuff.h>
#include <net/sock.h>

MODULE_LICENSE("GPL");
MODULE_AUTHOR("Yuri Jaschek");
MODULE_DESCRIPTION("@p4drv: p4 driver");

#define INTERFACE_NAME1 "eth0"
#define INTERFACE_NAME2 "eth1"
#define PKT_LEN 256

#define printp4(...) printk(KERN_INFO "@p4drv: " __VA_ARGS__);

// network interface card resources
static struct packet_type proto_listener1;
static struct packet_type proto_listener2;

static struct net_device *dev1;
static struct net_device *dev2;

static struct socket *sock1;
static struct socket *sock2;

static ktime_t curr;
static ktime_t prev;

/*static inline char my_printc(char c)
{
    return (c > 32 && c < 127) ? c : '.';
}

static void print_packet(char *data, int len)
{
    char *buffer, *ptr;
    int i, bsize = 4*len;
    if(len < 1) return;
    buffer = kmalloc(bsize, GFP_KERNEL);
    if(!buffer) return;

    ptr = buffer + sprintf(buffer, "%02x", data[0]);
    for(i=1; i<len; i++)
        ptr += sprintf(ptr, " %02x", data[i]);
    printp4("Packet (hexa): %s\n", buffer);

    ptr = buffer;
    for(i=0; i<len; i++)
        ptr += sprintf(ptr, "%c", my_printc(data[i]));
    printp4("Packet (view): %s\n", buffer);
    kfree(buffer);
}*/

static void
free_dev_and_sock(struct net_device **dev,
                  struct socket **sock)
{
    if(*dev) {
        dev_put(*dev);
        *dev = NULL;
    }
    if(*sock) {
        sock_release(*sock);
        *sock = NULL;
    }
}

static int
get_dev_and_sock(struct net_device **dev,
                 struct socket **sock,
                 const char *interface_name)
{
    *dev = dev_get_by_name(&init_net, interface_name); /// Freed with dev_put()
    if(*dev == NULL) {
        printp4("could not find interface %s\n", interface_name);
        return -1;
    }
    sock_create(PF_PACKET, SOCK_RAW, IPPROTO_RAW, sock); /// Freed with sock_release()
    if(*sock == NULL) {
        printp4("could not create a socket\n");
        return -1;
    }
    return 0 ;
}

int p4drv_recv(struct sk_buff *skb, struct net_device *dev,
               struct packet_type *pt, struct net_device *orig_dev)
{
    // from nic
    unsigned char *packet;
    int rc = -1;
    ktime_t time;

    time = curr = ktime_get();
    
    
    printk("packet at (%s) %llu ns gap %llu ns", dev ? dev->name : "", time, curr - prev);
    
    packet = (unsigned char *)skb_mac_header(skb);

    //printp4("method p4drv_recv called: skb->pkt_type %d, dev %s, packet_type %x\n",
    //        skb->pkt_type, dev ? dev->name : "", pt ? htons(pt->type) : 0
    //);
    
    // print_packet(packet, PKT_LEN);
    rc = 0;
    
    kfree_skb(skb);
    time = ktime_get() - time;
    prev = curr;
    //printk("time @ p4drv_recv @ %s: %llu ns", dev ? dev->name : "", time);
    return rc;
}

static int __init nl_p4_init(void)
{
    int err;

    // Get kernel networking stack structures
    err = get_dev_and_sock(&dev1, &sock1, INTERFACE_NAME1);
    if (err) {
        free_dev_and_sock(&dev1, &sock1);
        return -1;
    }

    err = get_dev_and_sock(&dev2, &sock2, INTERFACE_NAME2);
    if (err) {
        free_dev_and_sock(&dev1, &sock1);
        free_dev_and_sock(&dev2, &sock2);
        return -1;
    }

    proto_listener1.type = htons(ETH_P_ALL);
    proto_listener1.dev = dev1; /// NULL is a wildcard, listen on all interfaces
    proto_listener1.func = p4drv_recv;

    proto_listener2.type = htons(ETH_P_ALL);
    proto_listener2.dev = dev2; /// NULL is a wildcard, listen on all interfaces
    proto_listener2.func = p4drv_recv;

    /** Packet sockets are used to receive or send raw packets at the device
     * driver (OSI Layer 2) level. They allow the user to implement
     * protocol modules in user space on top of the physical layer.
     * 
     * Add a protocol handler to the networking stack.
     * The passed packet_type is linked into kernel lists and may not be freed until 
     * it has been removed from the kernel lists.
     */
    dev_add_pack (&proto_listener1);
    dev_add_pack (&proto_listener2);

    curr = prev = 0;

    printp4("nl_p4_init success, if_name: %s, %s\n", INTERFACE_NAME1, INTERFACE_NAME2);
    return 0;
}

static void __exit nl_p4_exit(void) {
    free_dev_and_sock(&dev1, &sock2);
    free_dev_and_sock(&dev2, &sock2);
    dev_remove_pack(&proto_listener1);
    dev_remove_pack(&proto_listener2);
    printp4("nl_p4_exit success!\n");
}

module_init(nl_p4_init);
module_exit(nl_p4_exit);
