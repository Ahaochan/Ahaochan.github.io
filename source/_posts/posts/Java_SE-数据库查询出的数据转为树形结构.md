---
title: 数据库查询出的数据转为树形结构
url: The_database_records_converted_to_tree_structure.
tags:
  - 最佳实践
categories:
  - Java SE
date: 2018-11-01 09:57:00
---
# 数据准备
假设有以下数据, 要建立树形结构
```text
id    pid    name
6      5     node6
5      2     node5
4      2     node4
3      1     node3
2      0     node2
1      0     node1
```

<!-- more -->

```java
public class TreeNode {
    private Integer id;
    private Integer pid;
    private String name;

    List<TreeNode> subTree;
    // 省略 getter 和 setter
}
```
数据库查出的都是`List`集合, 要转成树形结构只能用`Java`代码实现。
转化的方式有两种
1. 先查询出根节点, 再用`pid`递归查询数据库
2. 一次性查出所有的记录, 然后用`Java`代码组装树形结构

# 递归查询数据库(不推荐, 耗时长)
这种方法编写方便, 但是要进行频繁的数据库`IO`, 所以不推荐使用。
```
public interface DAO {
    List<TreeNode> getByPid(int pid);
}
public class TestService {
    private DAO dao = new DAO();
    public List<TreeNode> getTree() {
        return getTree(0);
    }
    private List<TreeNode> getTree(int pid) {
        List<TreeNode> parent = dao.getByPid(pid);
        for(TreeNode item : parent) {
            List<TreeNode> child = dao.getByPid(item.getId());
            item.setSubTree(child);
        }
        return parent;
    }
}
```
如果有`n`个节点, 那么就要查询`n`次数据库, 数量大了就会特别慢。

# 一次性查询出所有记录
既然数据库查询耗时长, 那么先一次性把所有数据查到内存中, 再自由组装树形结构。
```java
public class TreeNode {
    private Integer id;
    private Integer pid;
    private String name;

    List<TreeNode> subTree;
    // 省略 getter 和 setter

    public static List<TreeNode> source() {
        List<TreeNode> list = new ArrayList<>();
        list.add(new TreeNode(6, 5, "node6"));
        list.add(new TreeNode(5, 2, "node5"));
        list.add(new TreeNode(4, 2, "node4"));
        list.add(new TreeNode(3, 1, "node3"));
        list.add(new TreeNode(2, 0, "node2"));
        list.add(new TreeNode(1, 0, "node1"));
        return list;
    }
}
```
这里在内存中组装树形结构也有两种方法, 递归和循环。
```java
public class Main {
    public static void main(String[] args) {
        List<TreeNode> recursive = recursive(TreeNode.source());
        List<TreeNode> loop = loop(TreeNode.source());
        System.out.println(JSONObject.toJSONString(recursive));
        System.out.println(JSONObject.toJSONString(loop));
    }

    // ================= 循环构建 ======================
    public static List<TreeNode> loop(List<TreeNode> source) {
        List<TreeNode> topNodes = new ArrayList<TreeNode>();

        for (TreeNode node : source) {
            // 1. 获取 top 节点, 即没有 parent 节点的节点
            if (node.getPid() == 0) {
                topNodes.add(node);
            }
            // 2. 寻找 是否有节点的 parent 节点 为当前节点, 有则加入
            for (TreeNode find : source) {
                if (find.getPid().equals(node.getId())) {
                    if (node.getSubTree() == null) {
                        node.setSubTree(new ArrayList<TreeNode>());
                    }
                    node.getSubTree().add(find);
                }
            }
        }
        return topNodes;
    }

    // ================= 递归构建 ======================
    public static List<TreeNode> recursive(List<TreeNode> source) {
        List<TreeNode> trees = new ArrayList<>();
        for (TreeNode node : source) {
            // 1. 获取 top 节点, 即没有 parent 节点的节点
            if (node.getPid() == 0) {
                // 2. 寻找 是否有节点的 parent 节点 为当前节点, 有则加入
                trees.add(find(node, source));
            }
        }
        return trees;
    }

    public static TreeNode find(TreeNode parent, List<TreeNode> treeNodes) {
        for (TreeNode it : treeNodes) {
            if(parent.getId().equals(it.getPid())) {
                if (parent.getSubTree() == null) {
                    parent.setSubTree(new ArrayList<TreeNode>());
                }
                parent.getSubTree().add(find(it,treeNodes));
            }
        }
        return parent;
    }
}
```

# 参考资料
某篇CSDN博客, 后来找不到了