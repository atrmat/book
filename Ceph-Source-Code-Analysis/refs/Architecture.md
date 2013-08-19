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

![Ceph系统功能结构图](../images/architecture.png "图片标题")
