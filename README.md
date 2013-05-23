Chatty
======

While looking for an example of an iOS project that used Bonjour in a "client-server" context rather than the pure "peer to peer" example Apple provides with [WiTap](http://developer.apple.com/library/ios/#samplecode/WiTap/Introduction/Intro.html), I found a nice article by Peter Bakhyryev on Mobile Orchard, [Networking and Bonjour on iPhone](http://mobileorchard.com/tutorial-networking-and-bonjour-on-iphone) 

The sample project, Chatty, is a nice way to think about this problem.

The original code was distributed as a [zip file](http://www.mobileorchard.com/wp-content/uploads/2009/05/chatty.zip) and is now four years old, so I've brought it "up to date" for Xcode 4 and converted it to ARC. Other than some minor changes to make the UI visible on iOS 6.1, it's functionally the same as Peter wrote it. If you find any mistakes, please open a pull request.

Note: If you're looking for a more "modern" example, albeit only two-player to start, check this [mobiletuts+ tutorial](http://mobile.tutsplus.com/tutorials/iphone/creating-a-networked-game-with-bonjour-part-1/) by Bart Jacobs.