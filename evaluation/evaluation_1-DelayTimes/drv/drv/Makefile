obj-m += $(MAKE_OBJECT)
p4drv-objs := drv.o

KBUILD_CFLAGS += $(MAKE_FLAGS)

all:
	make -C /lib/modules/$(shell uname -r)/build M=$(shell pwd) modules

#clean:
#	make -C /lib/modules/$(shell uname -r)/build M=$(shell pwd) clean
