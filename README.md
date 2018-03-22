# CDChatList

[![CI Status](http://img.shields.io/travis/chdo002/CDChatList.svg?style=flat)](https://travis-ci.org/chdo002/CDChatList)
[![Version](https://img.shields.io/cocoapods/v/CDChatList.svg?style=flat)](http://cocoapods.org/pods/CDChatList)
[![License](https://img.shields.io/cocoapods/l/CDChatList.svg?style=flat)](http://cocoapods.org/pods/CDChatList)
[![Platform](https://img.shields.io/cocoapods/p/CDChatList.svg?style=flat)](http://cocoapods.org/pods/CDChatList)



 <img src="https://coding.net/u/chdo/p/CDResource/git/raw/master/gif1.GIF" width = "224" height = "400" alt="图片名称" align=center display=inline />
 <img src="https://coding.net/u/chdo/p/CDResource/git/raw/master/gif2.GIF" width = "224" height = "400" alt="图片名称" align=center display:inline/>



## 安装

```ruby
pod 'CDChatList'
```

## 使用

### 配置 CDChatList

ChatHelpr负责ChatHelpr的UI配置，及组件的资源文件设置
UI配置及资源文件都有默认，所以无需自定义的话，就可以跳过组件的配置

### 添加 CDChatList 视图


```
CDChatListView *list = [[CDChatListView alloc] initWithFrame:self.view.bounds];
list.msgDelegate = self;
self.listView = list;
[self.view addSubview:self.listView];
```

CDChatList会将视图控制器automaticallyAdjustsScrollViewInsets及contentInsetAdjustmentBehavior设为NO及Never，并适应导航栏高度

### 消息模型  MessageModalProtocal

消息模型需遵守MessageModalProtocal，实现相关属性

### 组件事件 ChatListProtocol

#### 从组件发出的消息

消息列表请求加载更多消息
```
-(void)chatlistLoadMoreMsg: (CDChatMessage)topMessage
callback: (void(^)(CDChatMessageArray))finnished;
```

消息中的点击事件
```
-(void)chatlistClickMsgEvent: (ChatListInfo *)listInfo;
```
#### 向组件发消息

添加新的数据到底部

```
-(void)addMessagesToBottom: (CDChatMessageArray)newBottomMsgArr;
```


更新数据源中的某条消息模型(主要是为了更新UI上的消息状态)

```
-(void)updateMessage:(CDChatMessage)message;
```

### 使用场景

#### 收/发消息

```Objective-C
// 发
{
MessageModal *modal;
}
-(void)send{
modal = [[MessageModal alloc] init];
modal.msgState = CDMessageStateSending;
modal.createTime = ...;
modal.msg = ...;
modal.msgType = ...;
[chatList addMessagesToBottom: modal];
}

-(void)sendCallBack:(BOOL)isSuccess{
modal.msgState = isSuccess;  // 此处应处理成枚举
[chatList updateMessage: modal];
}



// 收
-(void)receivedNewMessage:(MessageModal *)modal{
[chatList addMessagesToBottom: modal];
}

```

#### 下拉加载更多消息
消息列表被下拉时，触发此回调

```
-(void)chatlistLoadMoreMsg: (CDChatMessage)topMessage
callback: (void(^)(CDChatMessageArray))finnished
{
// 根据topMessage 获取更多消息
NSArray *msgArr = [self getMoreMessageFrom: topMessage amount: 10];
callback(msgArr);
}
```

#### 消息点击事件

目前消息体重处理了 文本点击 及 图片点击 事件

```
-(void)chatlistClickMsgEvent: (ChatListInfo *)listInfo{
if (listInfo.eventType == ChatClickEventTypeTEXT){
// 点击的文本
listInfo.clickedText
// 点击的文字位置  防止有相同的可点击文字
listInfo.range
// 被点击文本的隐藏信息   e.g.  <a title="转人工" href="doTransfer">
listInfo.clickedTextContent
} else if (listInfo.eventType == ChatClickEventTypeIMAGE){
// 图片
listInfo.image
// 图片在tableview中的位置
listInfo.msgImageRectInTableView
}
}
```



## TODO

- 自定义消息内容匹配
