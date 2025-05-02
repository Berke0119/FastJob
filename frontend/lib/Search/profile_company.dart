import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher_string.dart';

import '../Widgets/bottom_nav_bar.dart';
import '../user_state.dart';

class ProfileScreen extends StatefulWidget {
  final String userId;

  const ProfileScreen({required this.userId});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? name;
  String email = '';
  String phoneNumber = '';
  String imageUrl = '';
  String joinedAt = '';
  bool _isLoading = false;
  bool _isSameUser = false;

  void getUserData() async {
    try {
      _isLoading = true;
      final DocumentSnapshot userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(widget.userId)
          .get();

      if (userDoc == null) {
        return;
      } else {
        setState(() {
          name = userDoc.get('name');
          email = userDoc.get('email');
          phoneNumber = userDoc.get('phone');
          imageUrl = userDoc.get('imageUrl');
          Timestamp joinedAtTimeStamp = userDoc.get('joinedAt');
          var joinedDate = joinedAtTimeStamp.toDate();
          joinedAt = '${joinedDate.year}/${joinedDate.month}/${joinedDate.day}';
        });

        User? user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          if (user.uid == widget.userId) {
            setState(() {
              _isSameUser = true;
            });
          }
        }
      }
    } catch (e) {
      print(e);
    } finally {
      _isLoading = false;
    }
  }

  @override
  void initState() {
    super.initState();
    getUserData();
  }

  Widget userInfo({required IconData icon, required String content}) {
    return Row(
      children: [
        Icon(
          icon,
          color: Colors.white,
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          child: Text(
            content,
            style: const TextStyle(
              color: Colors.white54,
            ),
          ),
        )
      ],
    );
  }

  Widget _contactBy(
      {required Color color, required Function func, required IconData icon}) {
    return CircleAvatar(
      backgroundColor: color,
      radius: 25,
      child: IconButton(
        onPressed: () {
          func();
        },
        icon: Icon(
          icon,
          color: Colors.white,
        ),
      ),
    );
  }

  void _openWhatsapp() async {
    String url = 'https://wa.me/$phoneNumber?text=HelloWorld';
    await launchUrlString(url);
  }

  void _mailTo() async {
    final Uri params = Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=Write subject here&body=Hello, please write detail',
    );

    final url = params.toString();
    await launchUrlString(url);
  }

  void _callPhone() async {
    var url = 'tel://$phoneNumber';
    await launchUrlString(url);
  }

  @override
  Widget build(BuildContext context) {
    Size size = MediaQuery.of(context).size;
    return Container(
      decoration: BoxDecoration(
          gradient: LinearGradient(
        colors: [Colors.deepOrange.shade300, Colors.blueAccent],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      )),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        bottomNavigationBar: BottomNavigationBarForApp(indexNumber: 3),
        body: Center(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.only(top: 0.0),
                      child: Stack(
                        children: [
                          Card(
                            color: Colors.white10,
                            margin: const EdgeInsets.all(30.0),
                            elevation: 10,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const SizedBox(
                                    height: 130,
                                  ),
                                  Align(
                                    alignment: Alignment.center,
                                    child: Text(
                                      name == null ? 'Name Here' : name!,
                                      style: const TextStyle(
                                          color: Colors.white, fontSize: 24.00),
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 15,
                                  ),
                                  const Divider(
                                    color: Colors.white,
                                    thickness: 1,
                                  ),
                                  const SizedBox(
                                    height: 30,
                                  ),
                                  const Padding(
                                    padding: EdgeInsets.all(10.0),
                                    child: Text(
                                      'Account Information : ',
                                      style: TextStyle(
                                          color: Colors.white54,
                                          fontSize: 20.0),
                                    ),
                                  ),
                                  const SizedBox(
                                    height: 15,
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(left: 10.0),
                                    child: userInfo(
                                        icon: Icons.email, content: email),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.only(left: 10.0),
                                    child: userInfo(
                                        icon: Icons.phone,
                                        content: phoneNumber),
                                  ),
                                  const SizedBox(
                                    height: 30,
                                  ),
                                  const Divider(
                                    color: Colors.white,
                                    thickness: 1,
                                  ),
                                  const SizedBox(
                                    height: 15,
                                  ),
                                  _isSameUser
                                      ? const SizedBox()
                                      : Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceEvenly,
                                          children: [
                                            _contactBy(
                                                color: Colors.green,
                                                func: _openWhatsapp,
                                                icon: Icons.message_outlined),
                                            const SizedBox(
                                              width: 20,
                                            ),
                                            _contactBy(
                                                color: Colors.red,
                                                func: _callPhone,
                                                icon: Icons.call),
                                            const SizedBox(
                                              width: 20,
                                            ),
                                            _contactBy(
                                                color: Colors.blue,
                                                func: _mailTo,
                                                icon: Icons.email),
                                          ],
                                        ),
                                  const SizedBox(
                                    height: 15,
                                  ),
                                  _isSameUser
                                      ? const SizedBox()
                                      : const Divider(
                                          color: Colors.white,
                                          thickness: 1,
                                        ),
                                  const SizedBox(
                                    height: 30,
                                  ),
                                  _isSameUser
                                      ? Center(
                                          child: Padding(
                                            padding: const EdgeInsets.only(
                                                bottom: 30.0),
                                            child: MaterialButton(
                                              onPressed: () {
                                                FirebaseAuth.instance.signOut();
                                                Navigator.push(
                                                    context,
                                                    MaterialPageRoute(
                                                        builder: (context) =>
                                                            UserState()));
                                              },
                                              elevation: 10,
                                              color: Colors.black,
                                              textColor: Colors.white,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(14),
                                              ),
                                              child: const Padding(
                                                padding: EdgeInsets.symmetric(
                                                    vertical: 14.0),
                                                child: Text(
                                                  'Logout',
                                                  style: TextStyle(
                                                      fontFamily: 'Signatra',
                                                      fontSize: 30.0),
                                                ),
                                              ),
                                            ),
                                          ),
                                        )
                                      : const SizedBox(),
                                ],
                              ),
                            ),
                          ),
                          Padding(
                            padding:
                                const EdgeInsets.only(top: 30.0, bottom: 30),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Container(
                                  margin: const EdgeInsets.only(top: 30.0),
                                  height: size.width * 0.2,
                                  width: size.width * 0.2,
                                  decoration: BoxDecoration(
                                    border: Border.all(
                                      width: 3,
                                      color: Colors.black,
                                    ),
                                    shape: BoxShape.circle,
                                    image: DecorationImage(
                                      image: NetworkImage(
                                        imageUrl == ''
                                            ? 'https://www.pngitem.com/pimgs/m/146-1468479_my-profile-icon-blank-profile-picture-circle-hd.png'
                                            : imageUrl,
                                      ),
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                )
                              ],
                            ),
                          )
                        ],
                      ),
                    ),
                  )),
      ),
    );
  }
}
