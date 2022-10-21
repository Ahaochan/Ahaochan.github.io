---
title: PPT如何使用VBA批量替换字体
url: PPT_how_to_replace_font_by_vba
tags:
  - VBA
categories:
  - Microsoft Office
date: 2021-02-25 11:18:11
---

# 前言
最近有个需求, 需要将`PPT`内的字体全部修改为华文中宋, 并修改字号, 字符间距.
原以为可以和`notepad++`录制宏, 但是`office`居然把录制宏这个功能干掉了, 要实现这个需求, 只能自己写`VBA`.
本文从零开始学习`VBA`使用.

<!-- more -->

# 什么是VBA
> Visual Basic for Applications（VBA）是Visual Basic的一种宏语言，主要能用来扩展Windows的应用程序功能，特别是Microsoft Office软件。也可说是一种应用程序视觉化的Basic Script。 1994年发行的Excel 5.0版本中，即具备了VBA的宏功能。

以上来自维基百科, 在我看来就是可以应用在`office`全家桶的一个编程语言. 既然是编程语言, 那就肯定有数据结构, 变量, 流程控制语句等.

# PPT内的VBA对象
[`ActivePresentation`](https://docs.microsoft.com/en-us/office/vba/api/powerpoint.application.activepresentation): 返回一个`Presentation`对象, 该对象表示当前打开的`PPT`.
[`ActivePresentation.Slides`](https://docs.microsoft.com/en-us/office/vba/api/powerpoint.slides): 返回`PPT`内的幻灯片集合.
[`ActivePresentation.Slides.Shapes`](https://docs.microsoft.com/en-us/office/vba/api/powerpoint.slide.shapes): 返回幻灯片内的所有元素集合, 包括图片、文字等.
[`ActivePresentation.Slides.Shapes.TextFrame`](https://docs.microsoft.com/en-us/office/vba/api/powerpoint.shape.textframe): 修改元素内的文本属性
[`ActivePresentation.Slides.Shapes.TextFrame2`](https://docs.microsoft.com/en-us/office/vba/api/powerpoint.textframe2): 修改元素内的文本属性

`TextFrame`和`TextFrame2`都是可以修改文本属性. 不需要纠结它们有什么不同.

# VBA语法
[`Dim a As object`](https://docs.microsoft.com/en-us/office/vba/language/concepts/getting-started/declaring-variables): 声明`object`类型的对象变量`a`
[`For Each a In Array ... Next`](https://docs.microsoft.com/en-us/office/vba/language/concepts/getting-started/using-for-eachnext-statements): 循环遍历`Array`数组, 每个元素都赋值给变量`a`.
[`If...Then...Else`](https://docs.microsoft.com/en-us/office/vba/language/concepts/getting-started/using-ifthenelse-statements): 流程判断语句.
[`Not a`](https://docs.microsoft.com/en-us/dotnet/visual-basic/language-reference/operators/not-operator): 对表达式的值取反, 相当于`!a`.
[`With object ... End With`](https://docs.microsoft.com/en-us/office/vba/language/reference/user-interface-help/with-statement): 为`object`对象设置属性.
[`'我被单引号注释了`](https://docs.microsoft.com/en-us/dotnet/visual-basic/programming-guide/program-structure/comments-in-code): 单引号表示注释

# 完整例子
整个逻辑很简单, 就是循环遍历, 判断有文字就修改文字的属性.
如果有不想修改的属性, 打上单引号注释掉, 或者直接删掉那一行代码就可以了.
```
Sub ChangeFont()
    Dim oShape As Shape
    Dim oSlide As Slide
    Dim oTxtRange As TextRange
    On Error Resume Next
	
    For Each oSlide In ActivePresentation.Slides
        For Each oShape In oSlide.Shapes
            Set oTxtRange1 = oShape.TextFrame.TextRange
            If Not IsNull(oTxtRange1) Then
                With oTxtRange1.Font
                .NameFarEast = "华文中宋"           '中文字体名称
                .Name = "华文中宋"                  '字体名称
                .NameOther = "华文中宋"             '其他字体名称
                .Size = 20                          '字体大小
                .Color.RGB = RGB(Red:=0, Green:=0, Blue:=0) '字体颜色
                .Bold = False                       '是否加粗
                .Italic = False                     '是否倾斜
                .Shadow = False                     '是否阴影
                End With
            End If
            
            Set oTxtRange2 = oShape.TextFrame2.TextRange
            If Not IsNull(oTxtRange2) Then
                With oTxtRange2.Font
                .Spacing = 0                        '字体字符间距为普通
                End With
            End If
        Next
    Next
End Sub
```

# 总结
写`VBA`的主要难点是对`office`体系内的对象不了解, 就拿`TextFrame`和`TextFrame2`来说, 同样设置字体格式, 居然分为两个对象来设置.

目前的需求很简单, 已经能满足了, 如果后续有其他奇奇怪怪的需求, 再补充下这个代码.
