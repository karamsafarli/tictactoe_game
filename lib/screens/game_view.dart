import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;

class GameView extends StatefulWidget {
  const GameView(
      {super.key, required this.isMyRoom, this.roomID, required this.username});
  final bool isMyRoom;
  final String? roomID;
  final String username;

  @override
  State<GameView> createState() => _GameViewState();
}

class _GameViewState extends State<GameView> {
  var titleText = 'Waiting for the opponent...';
  final msgBox = Hive.box('user');
  var uuidRoomID = const Uuid().v4();
  IO.Socket? socket;
  var opponentName = '';
  var copyString = 'Click to copy room ID';
  var gameList = ['', '', '', '', '', '', '', '', ''];
  var isOtherPlayerJoined = false;
  bool isMyTurn = Random().nextBool();
  bool? isFirstPlayer;
  bool isGameOver = false;
  bool isGameStart = false;
  bool isDraw = false;
  var winner = '';

  @override
  void initState() {
    super.initState();
    socketConnection();
  }

  void socketConnection() {
    var username = msgBox.get('name');
    try {
      socket =
          IO.io('https://tictactoe-flutter-socket-96f5b2aca4ba.herokuapp.com/', <String, dynamic>{
        'transports': ['websocket'],
        'autoConnect': false
      });
      socket!.connect();
      socket!.onConnect((_) => print('Connected'));

      if (widget.isMyRoom) {
        setState(() {
          isFirstPlayer = isMyTurn;
        });
        socket!.emit('generate-room',
            {'roomID': uuidRoomID, 'username': username, 'isMyTurn': isMyTurn});

        socket!.emit('friend-join', username);

        socket!.on('opponent-name', (name) {
          setState(() {
            opponentName = name;
            isGameStart = true;
          });
        });
      } else {
        socket!
            .emit('join-room', {'roomID': widget.roomID, 'username': username});
        socket!.on('joined-friend-room', (data) {
          setState(() {
            isGameStart = true;
            opponentName = data['opponentName'];
            isMyTurn = data['isMyTurn'];
            isFirstPlayer = data['isMyTurn'];
          });
        });
      }

      socket!.on('play-changes', (idx) {
        setState(() {
          gameList[idx] = isFirstPlayer! ? 'O' : 'X';
          bool isWin = checkForWin();

          if (isWin) {
            winner = isMyTurn ? 'You' : opponentName;
            isGameOver = true;
          } else if (checkForDraw() && !isWin) {
            isDraw = true;
            isGameOver = true;
          } else {
            isMyTurn = !isMyTurn;
          }
        });
      });
    } catch (e) {
      print(e);
    }
  }

  void play(index) {
    var roomID = widget.isMyRoom ? uuidRoomID : widget.roomID;
    if (isMyTurn && gameList[index].isEmpty && !isGameOver && isGameStart) {
      setState(() {
        gameList[index] = isFirstPlayer! ? 'X' : 'O';
        bool isWin = checkForWin();
        socket!.emit('user-played', {'idx': index, "roomID": roomID});
        if (isWin) {
          winner = isMyTurn ? 'You' : opponentName;
          isGameOver = true;
        } else if (checkForDraw() && !isWin) {
          isDraw = true;
          isGameOver = true;
        } else {
          isMyTurn = !isMyTurn;
        }
      });
    }
  }

  @override
  void dispose() {
    socket!.dispose();
    socket!.disconnect();
    super.dispose();
  }

  bool horizontalWin(list) {
    bool isWin = false;
    for (var i = 0; i < list.length - 2; i++) {
      if (list[i] == list[i + 1] &&
          list[i + 1] == list[i + 2] &&
          list[i].isNotEmpty &&
          list[i + 1].isNotEmpty &&
          list[i + 2].isNotEmpty &&
          (i + 3) % 3 == 0) {
        isWin = true;
      }
    }

    return isWin;
  }

  bool verticalWin(list) {
    bool isWin = false;
    for (var i = 0; i < 3; i++) {
      if (list[i] == list[i + 3] &&
          list[i + 3] == list[i + 6] &&
          list[i].isNotEmpty &&
          list[i + 3].isNotEmpty &&
          list[i + 6].isNotEmpty) {
        isWin = true;
      }
    }

    return isWin;
  }

  bool diagonalWin(list) {
    bool isWin = false;
    bool firstDia =
        list[0].isNotEmpty && list[4].isNotEmpty && list[8].isNotEmpty;
    bool secondDia =
        list[2].isNotEmpty && list[4].isNotEmpty && list[6].isNotEmpty;
    if (((list[0] == list[4] && list[4] == list[8]) ||
            (list[2] == list[4] && list[4] == list[6])) &&
        (firstDia || secondDia)) {
      isWin = true;
    }

    return isWin;
  }

  bool checkForWin() {
    return verticalWin(gameList) ||
        horizontalWin(gameList) ||
        diagonalWin(gameList);
  }

  bool checkForDraw() {
    for (var i = 0; i < gameList.length; i++) {
      if (gameList[i].isEmpty) {
        return false;
      }
    }

    return true;
  }

  void copyText() async {
    setState(() {
      copyString = "Room ID copied to your clipboard ✔";
    });
    await Clipboard.setData(ClipboardData(text: uuidRoomID));
    Future.delayed(const Duration(seconds: 3), () {
      setState(() {
        copyString = 'Click to copy room ID';
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    var userFigure = isFirstPlayer != null
        ? isFirstPlayer!
            ? ['X', 'O']
            : ['O', 'X']
        : [];
    String whosTurn = opponentName.isEmpty
        ? 'Waiting for the player...'
        : (isMyTurn
            ? "Your turn - ${userFigure[0]}"
            : "$opponentName's turn - ${userFigure[1]}");
    return Scaffold(
      appBar: AppBar(
        title: Text(whosTurn),
        centerTitle: true,
      ),
      body: isGameOver
          ? Center(
              child: Text(
                isDraw
                    ? 'Draw'
                    : '$winner won - ${userFigure[isMyTurn ? 0 : 1]}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            )
          : Stack(
              children: [
                Center(
                  child: GridView.builder(
                    physics: const NeverScrollableScrollPhysics(),
                    shrinkWrap: true,
                    padding: const EdgeInsets.all(10),
                    itemCount: gameList.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      childAspectRatio: 1.0,
                    ),
                    itemBuilder: (context, idx) {
                      return Padding(
                        padding: const EdgeInsets.all(5),
                        child: InkWell(
                          onTap: () => play(idx),
                          child: Container(
                            alignment: Alignment.center,
                            color: Colors.purple[700],
                            child: Text(gameList[idx].toString(),
                                style: const TextStyle(
                                  fontSize: 40,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                )),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                if (widget.isMyRoom)
                  Positioned(
                    bottom: 10,
                    left: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: copyText,
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: Container(
                          padding: const EdgeInsets.all(15),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(10),
                            color: Colors.purple[100],
                            border: Border.all(
                                color: const Color.fromRGBO(74, 20, 140, 1),
                                width: 2),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            copyString,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
    );
  }
}
