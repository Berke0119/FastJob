import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:berkeserinfinal/Search/profile_company.dart';

class ApplicantsListPage extends StatelessWidget {
  final String jobId;

  const ApplicantsListPage({super.key, required this.jobId});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.deepOrange.shade300, Colors.blueAccent],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          flexibleSpace: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [Colors.deepOrange.shade300, Colors.blueAccent],
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
              ),
            ),
          ),
          title: const Text(
            "Applicants",
            style: TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
        ),
        body: FutureBuilder<DocumentSnapshot>(
          future:
              FirebaseFirestore.instance.collection('jobs').doc(jobId).get(),
          builder: (context, snapshot) {
            if (!snapshot.hasData) {
              return const Center(
                child: CircularProgressIndicator(
                  color: Colors.white,
                ),
              );
            }

            final jobData = snapshot.data!.data() as Map<String, dynamic>?;
            final List applications = jobData?['applications'] ?? [];

            if (applications.isEmpty) {
              return const Center(
                child: Text(
                  "No applications yet.",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                  ),
                ),
              );
            }

            // Skorların ortalamasına göre sırala (yüksekten düşüğe)
            applications.sort((a, b) {
              final aScore = a['score'] ?? 0;
              final aTrustScore = a['trustScore'] ?? 0;
              final bScore = b['score'] ?? 0;
              final bTrustScore = b['trustScore'] ?? 0;

              final aAverage = (aScore + aTrustScore) / 2;
              final bAverage = (bScore + bTrustScore) / 2;

              return bAverage.compareTo(aAverage);
            });

            return ListView.builder(
              padding: const EdgeInsets.all(8.0),
              itemCount: applications.length,
              itemBuilder: (context, index) {
                final app = applications[index];
                final userName = app['userName'] ?? 'Bilinmeyen';
                final userImageUrl = app['userImageUrl'] ?? '';
                final score = app['score'] ?? 0;
                final reason = app['reason'] ?? '';
                final userId = app['userId'] ?? '';
                final trustScore = app['trustScore'] ?? 0;
                final trustReason = app['trustReason'] ?? '';

                return Card(
                  color: Colors.black54,
                  margin: const EdgeInsets.symmetric(vertical: 8.0),
                  child: InkWell(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProfileScreen(userId: userId),
                        ),
                      );
                    },
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundImage: userImageUrl.isNotEmpty
                            ? NetworkImage(userImageUrl)
                            : const AssetImage('assets/images/default_user.png')
                                as ImageProvider,
                      ),
                      title: Text(
                        userName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Application Score: $score",
                            style: const TextStyle(
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Trust Score: $trustScore",
                            style: const TextStyle(
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Average Score: ${((score + trustScore) / 2).toStringAsFixed(1)}",
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Application Reason: $reason",
                            style: const TextStyle(
                              color: Colors.grey,
                            ),
                          ),
                          const SizedBox(height: 8),
                          if (trustReason.isNotEmpty)
                            Text(
                              "Trust Reason: $trustReason",
                              style: const TextStyle(
                                color: Colors.grey,
                              ),
                            ),
                        ],
                      ),
                      isThreeLine: true,
                    ),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
