var UDP = require('ti.udp');

var u = Ti.Android != undefined ? 'dp' : 0;
var win = Ti.UI.createWindow({
    backgroundColor: '#fff',
    layout: 'vertical'
});

/*
 Create our socket. 
 */
var socket = UDP.createSocket();

var broadcastGroup = Ti.UI.createTextField({
    hintText: 'Broadcast Group',
    height: 44 + u, top: 10 + u, left: 10 + u, right: 10 + u,
    borderStyle: Ti.UI.INPUT_BORDERSTYLE_ROUNDED,
    value: Ti.App.Properties.getString('BroadcastGroup', '239.192.13.37')
});
broadcastGroup.addEventListener('change', function(evt) {
    Ti.App.Properties.setString('BroadcastGroup', broadcastGroup.value);
});
win.add(broadcastGroup);

/*
 Start the server...
 */
var startSocket = Ti.UI.createButton({
    title: 'Start Socket',
    top: 10 + u, left: 10 + u, right: 10 + u, height: 40 + u
});
startSocket.addEventListener('click', function() {
    socket.start({
        port: 6100,
        group: broadcastGroup.value
    });
});
win.add(startSocket);

var sendTo = Ti.UI.createTextField({
    hintText: 'Send Directly To',
    height: 44 + u, top: 10 + u, left: 10 + u, right: 10 + u,
    borderStyle: Ti.UI.INPUT_BORDERSTYLE_ROUNDED,
    value: Ti.App.Properties.getString('SendTo', '')
});
sendTo.addEventListener('change', function(evt) {
    Ti.App.Properties.setString('SendTo', sendTo.value);
});
win.add(sendTo);

/*
 Send a string...
 */
var sendString = Ti.UI.createButton({
    title: 'Send String',
    top: 10 + u, left: 10 + u, right: 10 + u, height: 40 + u
});
sendString.addEventListener('click', function() {
    socket.sendString({
        host: sendTo.value,
        group: broadcastGroup.value,
        data: 'Hello, UDP!'
    });
});
win.add(sendString);

/*
 ... or send bytes.
 */
var sendBytes = Ti.UI.createButton({
    title: 'Send Bytes',
    top: 10 + u, left: 10 + u, right: 10 + u, height: 40 + u
});
sendBytes.addEventListener('click', function() {
    socket.sendBytes({
        host: sendTo.value,
        group: broadcastGroup.value,
        data: [ 181, 10, 0, 0 ]
    });
});
win.add(sendBytes);

/*
 Listen for when the server or client is ready.
 */
socket.addEventListener('started', function(evt) {
    status.text = 'Started!';
});

/*
 Listen for data from network traffic.
 */
socket.addEventListener('data', function(evt) {
    status.text = JSON.stringify(evt);
    Ti.API.info(JSON.stringify(evt));
});

/*
 Listen for errors.
 */
socket.addEventListener('error', function(evt) {
    status.text = JSON.stringify(evt);
    Ti.API.info(JSON.stringify(evt));
});

/*
 Finally, stop the socket when you no longer need network traffic access.
 */
var stop = Ti.UI.createButton({
    title: 'Stop',
    top: 10 + u, left: 10 + u, right: 10 + u, height: 40 + u
});
stop.addEventListener('click', function() {
    socket.stop();
});
win.add(stop);

var status = Ti.UI.createLabel({
    text: 'Press Start Socket to Begin',
    top: 10 + u, left: 10 + u, right: 10 + u, height: Ti.UI.SIZE || 'auto'
});
win.add(status);

win.open();