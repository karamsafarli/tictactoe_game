const express = require('express');
const http = require('http');
const { Server } = require('socket.io');

const app = express();
const server = http.createServer(app);


const io = new Server(server, {
    cors: {
        origin: '*'
    }
})

let connectedUsers = [];
let opponentName = '';
let myturn;

// io.on('connection', (socket) => {
//     console.log(`Connected: ${socket.id}`)
//     connectedUsers.push(socket.id)
//     console.log(connectedUsers)

//     // socket.on('send-message', (message) => {
//     //     io.emit('receive-message', message)
//     // });

//     socket.on('join-room', roomID => {
//         socket.join(roomID);
//     });

//     socket.on('send-private-msg', ({ msg, roomID }) => {
//         io.to(roomID).emit('receive-private-msg', msg);
//     });
// });



// app.get('/', (req, res) => {
//     res.send("salam")
// })

// app.listen(3000, () => {
//     console.log('Listening...')
// })
app.get('/', (req, res) => {
    res.send('salam')
})

io.on('connection', (socket) => {
    console.log("user connected", socket.id)
    socket.on('connected-user', (data) => {
        console.log(data)
    });

    socket.on('generate-room', ({ roomID, username, isMyTurn }) => {
        // console.log(username)
        socket.join(roomID);
        opponentName = username;
        myturn = isMyTurn;
    });

    socket.on('join-room', ({ roomID, username }) => {
        console.log(opponentName, myturn)
        socket.join(roomID);
        socket.to(roomID).emit('opponent-name', username);
        let isMyTurn = !myturn;
        io.to(roomID).emit('joined-friend-room', { opponentName, isMyTurn });
    });

    socket.on('user-played', ({idx,roomID}) => {
        socket.broadcast.to(roomID).emit('play-changes', idx);
    })
});

server.listen(3001, '0.0.0.0', () => {
    console.log('Server is listening...')
})