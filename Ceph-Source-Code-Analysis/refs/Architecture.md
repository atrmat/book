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

![Ceph系统功能结构图](./images/architecture.png "Ceph存储系统功能结构图")

图1.1  Ceph系统功能结构图

从图1.1中，可以看出Ceph主要是基于[RADOS](./pdfs/weil-rados-pdsw07.pdf)文件系统实现了其功能。

*注意：RADOS可以参考论文《[RADOS: A Scalable, Reliable Storage Service for Petabyte-scale
Storage Clusters](./pdfs/weil-rados-pdsw07.pdf)》*

# 2 The Ceph Storage Cluster

Ceph在RADOS文件系统的基础上，能够提供一个无限扩张的Ceph Storage Cluster。
Ceph能够提供这么强大的数据功能，那么问题是：Ceph是如何定位一个数据块的呢？
对于Storage Cluster Clients和Ceph OSD Daemon而言，都需要精确地定位一个数据
块的位置。此时就需要借助于CRUSH算法。CRUSH算法并不需要去查看一张“居于中心管
理记录地位的表单”，就可以计算出数据存放的位置。对于上层应用程序而言，Ceph还
提供了“native”的Ceph Storage Cluster的接口librados。此外，一系列服务与程序
都基于librados与RADOS进行交互。

*注意：Ceph OSD Daemon：管理一个逻辑磁盘的后台运行服务。OSD主要是指一个逻辑磁盘。
然而，在Ceph中，经常是把OSD与Ceph OSD Daemon混合使用，这两者很有可能都是指这个后台服务。*

## 存储数据

对于Ceph存储系统而言，数据的来源主要有四种：
- Ceph Block Device
- Ceph Object Storage
- Ceph Filesystem
- APP based on librados

Ceph并不去计较这些数据是从哪里得到的，统一地把这些数据当作对象进行存储。
对象只是一个抽象的称呼而已，如何一个实物对应起来呢？
实际上指的是文件系统上的一个文件。这个文件最终将存放在存储设备上。
在底层上，主要是由Ceph OSD Daemons来处理存储设备上的读写操作。
这也就意味着Ceph的存储经历了：Object->File->Disk的流程。
如图1.2所示：

![对象存储流程图](./images/object-file-disk.png "对象存储流程图")

图1.2  对象存储流程图

Ceph OSD Daemons将所有的数据都当成对象存储在一个平面名称空间中
（也就是说没有层级结构，比如一般的目录树什么的，也都没有了）。
一个对象文件有：
- Identifier：对象文件的ID，整个Cluster中必须没有相同的ID。
- Binary Data：二进制数据，是对象文件数据本身。
- metadata：metadata一般是称之为数据的信息，也称为数据的数据。主要是由一系列健值对构成。metadata主要是在Filesystem中用得比较多，比如文件所有者、创建日期、最近修改日期等等。

![对象文件示意图](./images/id-binary-metadata.png "对象文件示意图")

图1.3  对象文件示意图

*注意：identifier也就是通常意义上指的ID，对象文件的ID是针对整个Cluster而言的。
需要保证在一个Cluster中，其ID也是唯一的。*


## 扩展性与高可用性

在传统的架构中，client如果想要去系统进行交互，需要与一个控制结点打交道。
在一个复杂而又庞大的系统中，引发的单点故障非常恼火。
这种传统的控制系统会带来三方面的问题：
- 性能制约：由于所有的client都需要与控制结点打交道，会导致控制结节非常繁忙。
- 影响扩展：控制节点所管理的节点数目总归是有限的，当系统扩展时，急剧上升的节点数目会带来易想不到的问题。
- 单点失效：当控制节点宕机之后，整个系统都会变得不可用。

Ceph作为一个高可用、高扩展性的存储系统，肯定是不能采用这种传统的架构。Ceph采取的策略有：
- 无主控节点的结构：Ceph采用了Client工具直接与Ceph OSD Daemons交互的方法。
- 高扩展性：由于没有控制节点的制约，Ceph的扩展变得极为容易。
- 高可用性：Ceph OSD Daemons在存储对象时，除了在它所管理的存储设备上存放数据之外，还会将此数据复制至其他节点，以保证数据的高安全性。
- 高可靠性：Ceph系统除了Storage Cluster之外，还有Monitor Cluster。Monitor Cluster会监控Storage Cluster的运行状态。此外，Monitor Cluster自身也有相应的高可靠机制。

那么，Ceph是如何达到这些目标的呢？主要是利用了CRUSH算法。


### CRUSH算法简介

对于Ceph系统而言，主要是有两类程序需要不停地存取数据：
- Ceph客户端程序：使用Ceph系统的人，把数据存放至Ceph中。
- Ceph OSD Daemons：Ceph OSD Daemons为什么需要经常性地存取数据呢？主要因为Ceph OSD Daemons需要在Ceph Nodes之间同步与复制数据。

不管是Ceph Client还是Ceph OSD Daemons，都是利用了CRUSH算法来定位需要的数据的具体位置，而不是再去查“记录了整个集群信息的表单”。

CRUSH提供的数据管理策略，比以往实现的方法都要好。这种“去中心化”的策略，能够带来良好的扩展性。无论是Ceph Client还是Ceph OSD Daemons查找数据，都是将这个查找定位的工作量分布到整个集群中。此外，CRUSH还利用了弹性的数据复制方案。这种灵活性，可以很轻易将Ceph地扩展至大规模集群。下面将大致介绍CRUSH的操作流程，详细的参考资料请阅读论文《[CRUSH - Controlled, Scalable, Decentralized Placement of Replicated Data](./pdfs/weil-rados-pdsw07.pdf)》。

### Cluster Map

Ceph能够有效地进行分布式数据读取的一个很重要的原因是：假设数据读取方完全了解Cluster的拓扑结构。这也就意味着Ceph Client和Ceph OSD Daemon都了解Cluster的拓扑结构。在读取数据时，就可以直接向相应的Ceph Node要数据了。

那么，Ceph Cluster的拓扑结构是怎么样的呢？首先其拓扑结构，在Ceph中命名Cluster Map。而Cluster Map是如下几种Map的统称：

1. The Monitor Map：包括了Cluster fsid、位置、name address以及每个monitor的端口。也保存着当前的更新点（Ceph Cluster的变动会导致拓扑结构的变动，称之为epoch）。如果要查看一个monitor map，可以运行命令：`ceph mon dump`。

2. The OSD Map：包含了Cluster的fsid、当前map创建时间、最后修改时间、存储池列表、PG数目、OSDs列表及其状态（eg., up, in）。如果要查看一个OSD map，可以运行`ceph osd dump`。

3. The PG Map：包含了PG（placement group）版本、时间戳、最新的OSD map更新点、满载率。此外，还记录了每个PG详细信息：PG ID、Up Set、Acting Set、PG的状态（比如active + clean）、每个存储池中的数据使用频率统计。

4. The CRUSH Map：包含了一系列存储设备以及失败的层次（比如一个设备、主机、机架、一排、一个机房都出现了故障）、以及数据在层次之间的传输规则。如果要查看一个CRUSH map，可以执行以下命令。当拿到解析之后的CRUSH map之后，可以通过`cat`命令进行查看，或者直接用文本编辑器打开。

    ceph osd getcrushmap -o {filename}
    crushtool -d {comp-crushmap-filename} -o {decomp-crushmap-filename}

5. The MDS Map：包含了当前的MDS Map更新点。这个MDS map也包含了存储metadata的存储池、metadata服务器列表、以些这些服务器的状态。如果要查看MDS map的状态，可以执行`ceph mds dump`。

每个map都维护着自己不断被更改的历史记录。Ceph Monitors维护着cluster map的备份（这里面包含着cluster成员、状态、更改记录、Ceph Storage Cluster的健康状态）。

### 高可靠的Monitors

在Ceph Clients或者Ceph OSD Daemons开始读或者写数据之前，需要向Cluster Monitor获取当前最新状态的Cluster Map。有了最新的Cluster Map才能保证读或者写的数据是正常的。由于在读写数据之前，需要先与Cluster Monitor打交道，所以需要保证Cluster Monitor的高可靠性。

一种最简单的办法是：一个Ceph Storage Cluster中只安装一个Ceph Cluster Monitor。这种偷懒的策略会带来单点失效的问题（假如Monitor节点宕机，那么无论是Ceph Client还是Ceph OSD Daemons都无法读取数据）。

为了增加可靠性以及容错性，Ceph支持将Monitors部署成一个集群。在一个Monitors集群中，
