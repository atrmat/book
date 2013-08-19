Ceph的框架
===================

# 1 框架

Ceph将对象存储、块存储、文件存储统一到一个存储系统中。
Ceph的目标是实现一个高可靠、易管理、免费的存储系统。
借助于Ceph的力量，可以轻易地转变公司IT部门的结构，还可以管理海量数据。
除此之外，Ceph还拥有超强的扩展能力，能够支持成千上万的客户端。
Ceph的数据容量已持续爆炸性增长到拍字节（Petabytes）和艾字节(Exabytes）。

## 三个重要组成部分

- Ceph Node：构成存储所必须的硬件及相应的守护进程。
- Ceph Storage Cluster：由一系列的Ceph Node组成，位于Cluster中的Ceph Node会相互通信以保持数据的备份及动态地分发。
- Ceph Monitor：Ceph Monitor也是由一系列节点组成，只不过其功能主要是用于监控位于Ceph Storage Cluster中的Ceph Node。可能会问，位于Ceph Monitor中的节点是否也是要监控呢？答案是Ceph Monitor Cluster内部已经采用了高可用的机制。

## Ceph功能结构图

按照Ceph的目标，其功能主要是分为三方面：
- 对象存储：（reliable, autonomic, distributed object store gateway, RADOSGW）一个基于桶的REST端口，能够兼容S3（亚马逊提供的对象存储接口）、及Swift接口（OpenStack提供的对象存储接口）。
- 块存储：（reliable block device, RBD）一个可靠、完全分布式的块设备。并且提供了Linux Kernel Client，以及QEMU/KVM相应的驱动。
- Ceph FS：（Ceph file system, CEPHFS）兼容POSIX的分布式文件系统。给Linux Kernel提供了客户端工具，并且同时支持[FUSE](http://fuse.sourceforge.net/)。

Ceph的功能结构如图1.1所示。
除了Ceph的三个目标之外，此外还有一个功能是直接提供给应用程序。
只不过此时实际功能直接是由底层的RADOS提供，其接口命名为LIBRADOS。

*注意：FUSE是指Filesystem in Userspace。*

![Ceph系统功能结构图](../images/architecture.png "Ceph存储系统功能结构图")

图1.1  Ceph系统功能结构图

从图1.1中，可以看出Ceph主要是基于[RADOS](../pdfs/weil-rados-pdsw07.pdf)文件系统实现了其功能。

# 2 The Ceph Storage Cluster

Ceph在RADOS文件系统的基础上，能够提供一个无限扩张的Ceph Storage Cluster。
Ceph能够提供这么强大的数据功能，那么问题是：Ceph是如何定位一个数据块的呢？
对于Storage Cluster Clients和Ceph OSD Daemon而言，都需要精确地定位一个数据
块的位置。此时就需要借助于**CRUSH算法**。CRUSH算法并不需要去查看一张“居于中心管
理记录地位的表单”，就可以计算出数据存放的位置。对于上层应用程序而言，Ceph还
提供了“native”的Ceph Storage Cluster的接口librados。此外，一系列服务与程序
都基于librados与RADOS进行交互。

*注意：Ceph OSD Daemon：管理一个逻辑磁盘的后台运行服务。OSD主要是指一个逻辑磁盘。
然而，在Ceph中，经常是把OSD与Ceph OSD Daemon混合使用，这两者很有可能都是指这个后台服务。*
