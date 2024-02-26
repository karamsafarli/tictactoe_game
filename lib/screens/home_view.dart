import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:tictactoe_game/screens/game_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  final _enteredNickname = TextEditingController();
  final _enteredRoomID = TextEditingController();
  final _myBox = Hive.box('user');

  @override
  void initState() {
    super.initState();
    var nick = _myBox.get('name');
    if (nick != null) {
      _enteredNickname.text = nick;
    }
  }

  @override
  void dispose() {
    _enteredNickname.dispose();
    _enteredRoomID.dispose();
    super.dispose();
  }

  void _storeNickname(BuildContext context) async {
    if (_enteredNickname.text.isEmpty) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your nickname first.'),
        ),
      );
      return;
    }

    await _myBox.put('name', _enteredNickname.text);
  }

  void _joinRoom(BuildContext context, String roomid) {
    _storeNickname(context);

    if (_enteredNickname.text.isEmpty) return;

    if (_enteredRoomID.text.isEmpty) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Room ID must not be empty!'),
        ),
      );
      return;
    }

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GameView(
          isMyRoom: false,
          roomID: roomid,
          username: _enteredNickname.text,
        ),
      ),
    );
  }

  void _generateNewRoom(BuildContext context) {
    _storeNickname(context);

    if (_enteredNickname.text.isEmpty) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => GameView(
          isMyRoom: true,
          username: _enteredNickname.text,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.purple[100],
      appBar: AppBar(
        backgroundColor: Colors.purple[100],
        title: const Text('TicTacToe Game'),
        centerTitle: true,
      ),
      body: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Text(
              'Invite a friend or join room',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleLarge!.copyWith(
                  color: Colors.purple[800], fontWeight: FontWeight.bold),
            ),
            const SizedBox(
              height: 40,
            ),
            TextFormField(
              controller: _enteredNickname,
              decoration: const InputDecoration(
                labelText: 'Your Nickname',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
              ),
            ),
            const SizedBox(height: 50),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _enteredRoomID,
                    decoration: const InputDecoration(
                      labelText: 'Enter room ID',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.all(Radius.circular(12)),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 15),
                ElevatedButton(
                  onPressed: () => _joinRoom(context, _enteredRoomID.text),
                  child: SizedBox(
                    height: 60,
                    child: Center(
                      child: Text(
                        'JOIN',
                        style: Theme.of(context).textTheme.titleLarge!.copyWith(
                            color: Colors.purple[600],
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Text(
                'or',
                style: Theme.of(context).textTheme.bodyLarge,
              ),
            ),
            ElevatedButton(
              onPressed: () => _generateNewRoom(context),
              child: SizedBox(
                height: 60,
                width: double.infinity,
                child: Center(
                  child: Text(
                    'Generate new room',
                    style: Theme.of(context).textTheme.titleLarge!.copyWith(
                        color: Colors.purple[700], fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
