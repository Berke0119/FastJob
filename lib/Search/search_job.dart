import 'package:berkeserinfinal/Jobs/jobs_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../Widgets/job_widget.dart';

class SearchScreen extends StatefulWidget {
  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final TextEditingController _searchController = TextEditingController();
  String searchQuery = 'Search query';

  Widget _buildSearchField() {
    return TextField(
      controller: _searchController,
      autocorrect: true,
      decoration: const InputDecoration(
        hintText: 'Search...',
        border: InputBorder.none,
        hintStyle: TextStyle(color: Colors.white),
      ),
      style: const TextStyle(color: Colors.white, fontSize: 16.0),
      onChanged: (query) => _updateSearchQuery(query),
    );
  }

  List<Widget> _buildActions() {
    return <Widget>[
      IconButton(
        onPressed: () {
          _clearSearch();
        },
        icon: const Icon(Icons.clear),
      ),
    ];
  }

  void _clearSearch() {
    setState(() {
      _searchController.clear();
      searchQuery = 'Search query';
    });
  }

  void _updateSearchQuery(String newQuery) {
    setState(() {
      searchQuery = newQuery;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
          gradient: LinearGradient(
        colors: [Colors.deepOrange.shade300, Colors.blueAccent],
        begin: Alignment.centerLeft,
        end: Alignment.centerRight,
      )),
      child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            flexibleSpace: Container(
              decoration: BoxDecoration(
                  gradient: LinearGradient(
                colors: [Colors.deepOrange.shade300, Colors.blueAccent],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              )),
            ),
            leading: IconButton(
              onPressed: () {
                Navigator.pushReplacement(context,
                    MaterialPageRoute(builder: (context) => JobScreen()));
              },
              icon: const Icon(Icons.arrow_back),
            ),
            title: _buildSearchField(),
            actions: _buildActions(),
          ),
          body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('jobs')
                .where('jobTitle', isGreaterThanOrEqualTo: searchQuery)
                .where('recruitment', isEqualTo: true)
                .snapshots(),
            builder: (context,
                AsyncSnapshot<QuerySnapshot<Map<String, dynamic>>> snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(
                  child: CircularProgressIndicator(
                    color: Colors.cyan,
                  ),
                );
              }

              if (snapshot.hasError) {
                debugPrint("Error: ${snapshot.error}");
                return const Center(
                  child: Text(
                    'Something went wrong',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 30),
                  ),
                );
              }

              if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Text('No Jobs Found'),
                );
              }

              // Veriler mevcutsa, listeyi göster
              final docs = snapshot.data!.docs;

              return ListView.builder(
                itemCount: docs.length,
                itemBuilder: (context, index) {
                  final jobData = docs[index].data();

                  return JobWidget(
                    jobTitle: jobData['jobTitle'] ?? 'No Title',
                    jobDescription:
                        jobData['jobDescription'] ?? 'No Description',
                    jobId: jobData['jobId'] ?? '',
                    uploadedBy: jobData['uploadedBy'] ?? '',
                    userImage: jobData['userImage'] ?? '',
                    name: jobData['name'] ?? '',
                    recruitment: jobData['recruitment'] ?? false,
                    email: jobData['email'] ?? '',
                    location: jobData['location'] ?? '',
                  );
                },
              );
            },
          )),
    );
  }
}
