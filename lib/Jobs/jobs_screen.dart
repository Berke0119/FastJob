import 'package:berkeserinfinal/Persistent/persistent.dart';
import 'package:berkeserinfinal/Search/search_job.dart';
import 'package:berkeserinfinal/Widgets/bottom_nav_bar.dart';
import 'package:berkeserinfinal/Widgets/job_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class JobScreen extends StatefulWidget {
  @override
  State<JobScreen> createState() => _JobScreenState();
}

class _JobScreenState extends State<JobScreen> {
  String? _jobCategoryFilter = '';

  final FirebaseAuth _auth = FirebaseAuth.instance;

  _showTaskCategoriesDialog({required Size size}) {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            backgroundColor: Colors.black54,
            title: const Text(
              'Job Category',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.white, fontSize: 20),
            ),
            content: Container(
              width: size.width * 0.9,
              child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: Persistent.jobCategoryList.length,
                  itemBuilder: (context, index) {
                    return InkWell(
                      onTap: () {
                        setState(() {
                          _jobCategoryFilter =
                              Persistent.jobCategoryList[index];
                        });
                        Navigator.pop(context);
                      },
                      child: Row(
                        children: [
                          const Icon(
                            Icons.arrow_right_alt_outlined,
                            color: Colors.grey,
                          ),
                          Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Text(
                              Persistent.jobCategoryList[index],
                              style: const TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                },
                child: const Text(
                  'Close',
                  style: TextStyle(color: Colors.green, fontSize: 18),
                ),
              ),
              TextButton(
                  onPressed: () {
                    setState(() {
                      _jobCategoryFilter = '';
                    });
                    Navigator.pop(context);
                  },
                  child: const Text(
                    'Cancel Filter',
                    style: TextStyle(color: Colors.green, fontSize: 18),
                  )),
            ],
          );
        });
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
        bottomNavigationBar: BottomNavigationBarForApp(
          indexNumber: 0,
        ),
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          title: _jobCategoryFilter == ''
              ? const Text(
                  'All Jobs',
                  style: TextStyle(fontFamily: 'Signatra', fontSize: 35),
                )
              : Text(
                  _jobCategoryFilter!,
                  style: const TextStyle(fontFamily: 'Signatra', fontSize: 35),
                ),
          centerTitle: true,
          flexibleSpace: Container(
            decoration: BoxDecoration(
                gradient: LinearGradient(
              colors: [Colors.deepOrange.shade300, Colors.blueAccent],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            )),
          ),
          automaticallyImplyLeading: false,
          leading: IconButton(
            onPressed: () {
              _showTaskCategoriesDialog(size: size);
            },
            icon: const Icon(
              Icons.filter_list_rounded,
              color: Colors.black,
            ),
          ),
          actions: [
            IconButton(
              onPressed: () {
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (context) => SearchScreen()));
              },
              icon: const Icon(Icons.search, color: Colors.black),
            )
          ],
        ),
        body: _jobCategoryFilter == ''
            ? StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('jobs')
                    .where('recruitment', isEqualTo: true)
                    .orderBy('createdAt', descending: false)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Colors.cyan,
                      ),
                    );
                  } else if (snapshot.connectionState ==
                      ConnectionState.active) {
                    if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                      return ListView.builder(
                        itemCount: snapshot.data!.docs.length,
                        itemBuilder: (context, index) {
                          return JobWidget(
                            jobTitle: snapshot.data!.docs[index]['jobTitle'],
                            jobDescription: snapshot.data!.docs[index]
                                ['jobDescription'],
                            jobId: snapshot.data!.docs[index]['jobId'],
                            uploadedBy: snapshot.data!.docs[index]
                                ['uploadedBy'],
                            userImage: snapshot.data!.docs[index]['userImage'],
                            name: snapshot.data!.docs[index]['name'],
                            recruitment: snapshot.data!.docs[index]
                                ['recruitment'],
                            email: snapshot.data!.docs[index]['email'],
                            location: snapshot.data!.docs[index]['location'],
                          );
                        },
                      );
                    } else {
                      return const Center(
                        child: Text('No Jobs Found'),
                      );
                    }
                  } else if (snapshot.hasError) {
                    return const Center(
                      child: Text(
                        'Something went wrong',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 30),
                      ),
                    );
                  } else {
                    return const Center(
                      child: Text('No Jobs Found'),
                    );
                  }
                },
              )
            : StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                stream: FirebaseFirestore.instance
                    .collection('jobs')
                    .where('jobCategory', isEqualTo: _jobCategoryFilter)
                    .where('recruitment', isEqualTo: true)
                    .orderBy('createdAt', descending: false)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(
                        color: Colors.cyan,
                      ),
                    );
                  } else if (snapshot.connectionState ==
                      ConnectionState.active) {
                    if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
                      return ListView.builder(
                        itemCount: snapshot.data!.docs.length,
                        itemBuilder: (context, index) {
                          return JobWidget(
                            jobTitle: snapshot.data!.docs[index]['jobTitle'],
                            jobDescription: snapshot.data!.docs[index]
                                ['jobDescription'],
                            jobId: snapshot.data!.docs[index]['jobId'],
                            uploadedBy: snapshot.data!.docs[index]
                                ['uploadedBy'],
                            userImage: snapshot.data!.docs[index]['userImage'],
                            name: snapshot.data!.docs[index]['name'],
                            recruitment: snapshot.data!.docs[index]
                                ['recruitment'],
                            email: snapshot.data!.docs[index]['email'],
                            location: snapshot.data!.docs[index]['location'],
                          );
                        },
                      );
                    } else {
                      return const Center(
                        child: Text('No Jobs Found'),
                      );
                    }
                  } else if (snapshot.hasError) {
                    return const Center(
                      child: Text(
                        'Something went wrong',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 30),
                      ),
                    );
                  } else {
                    return const Center(
                      child: Text('No Jobs Found'),
                    );
                  }
                },
              ),
      ),
    );
  }
}
