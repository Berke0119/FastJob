import 'package:berkeserinfinal/Jobs/jobs_screen.dart';
import 'package:berkeserinfinal/Widgets/comments_widget.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:uuid/uuid.dart';
import '../Services/global_methods.dart';
import 'dart:io';
import 'dart:convert';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:syncfusion_flutter_pdf/pdf.dart';
import 'package:berkeserinfinal/Jobs/applicants_list_page.dart';

class JobDetails extends StatefulWidget {
  final String uploadedBy;
  final String jobId;

  const JobDetails({
    required this.uploadedBy,
    required this.jobId,
  });

  @override
  State<JobDetails> createState() => _JobDetailsState();
}

class _JobDetailsState extends State<JobDetails> {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  bool _isCommenting = false;
  final TextEditingController _commentController = TextEditingController();
  bool showComments = false;

  String? authorName;
  String? userImageUrl;
  String? jobCategory;
  String? jobDescription;
  String? jobTitle;
  bool? recruitment;
  Timestamp? postedDateTimeStamp;
  Timestamp? deadlineDateTimeStamp;
  String? postedDate;
  String? deadlineDate;
  String? location = '';
  String? emailCompany = '';
  int applicants = 0;
  bool isDeadlineAvailable = false;

  void getJobData() async {
    final DocumentSnapshot userDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(widget.uploadedBy)
        .get();

    if (userDoc == null) {
      return;
    } else {
      setState(() {
        authorName = userDoc.get('name');
        userImageUrl = userDoc.get('imageUrl');
      });
    }
    final DocumentSnapshot jobDoc = await FirebaseFirestore.instance
        .collection('jobs')
        .doc(widget.jobId)
        .get();

    if (jobDoc == null) {
      return;
    } else {
      setState(() {
        jobCategory = jobDoc.get('jobCategory');
        jobDescription = jobDoc.get('jobDescription');
        jobTitle = jobDoc.get('jobTitle');
        recruitment = jobDoc.get('recruitment');
        postedDateTimeStamp = jobDoc.get('createdAt');
        deadlineDateTimeStamp = jobDoc.get('deadlineDateTimestamp');
        location = jobDoc.get('location');
        emailCompany = jobDoc.get('email');
        applicants = jobDoc.get('applicants');
        var postDate = postedDateTimeStamp!.toDate();
        var deadlineDateObj = deadlineDateTimeStamp!.toDate();
        postedDate = '${postDate.year}/${postDate.month}/${postDate.day}';
        deadlineDate =
            '${deadlineDateObj.year}/${deadlineDateObj.month}/${deadlineDateObj.day}';
      });

      var date = deadlineDateTimeStamp!.toDate();
      isDeadlineAvailable = date.isAfter(DateTime.now());
    }
  }

  @override
  void initState() {
    getJobData();
    super.initState();
  }

  Widget dividerWidget() {
    return const Column(
      children: [
        SizedBox(
          height: 10,
        ),
        Divider(
          thickness: 1,
          color: Colors.grey,
        ),
        SizedBox(
          height: 10,
        ),
      ],
    );
  }

  applyForJob() async {
    try {
      if (emailCompany == null || emailCompany!.isEmpty) {
        Fluttertoast.showToast(
          msg: "Email address not found",
          toastLength: Toast.LENGTH_LONG,
          backgroundColor: Colors.grey,
          fontSize: 18,
          textColor: Colors.red[800],
        );
        return;
      }

      // Basit mailto URL'si oluştur
      final url = 'mailto:$emailCompany';

      // URL'yi açmayı dene
      final canLaunch = await canLaunchUrlString(url);
      if (canLaunch) {
        await launchUrlString(url);
        addNewApplicant();
      } else {
        Fluttertoast.showToast(
          msg:
              "Could not open email client. Please send your application to: $emailCompany",
          toastLength: Toast.LENGTH_LONG,
          backgroundColor: Colors.grey,
          fontSize: 18,
          textColor: Colors.red[800],
        );
        addNewApplicant();
      }
    } catch (e) {
      print("Email error: $e"); // Hata ayıklama için
      Fluttertoast.showToast(
        msg: "Error: $e\nPlease send your application to: $emailCompany",
        toastLength: Toast.LENGTH_LONG,
        backgroundColor: Colors.grey,
        fontSize: 18,
        textColor: Colors.red[800],
      );
      addNewApplicant();
    }
  }

  void addNewApplicant() async {
    try {
      var docRef =
          FirebaseFirestore.instance.collection('jobs').doc(widget.jobId);
      await docRef.update({'applicants': FieldValue.increment(1)});
      getJobData(); // Başvuran sayısını güncelle
    } catch (e) {
      print("Error updating applicants count: $e");
    }
  }

  Future<void> selectAndSubmitCV() async {
    // 1. Kullanıcıdan PDF dosyasını al
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );

    if (result == null || result.files.single.path == null) {
      Fluttertoast.showToast(msg: "PDF seçilmedi ❌");
      return;
    }

    try {
      final file = File(result.files.single.path!);
      final bytes = await file.readAsBytes();

      // 2. PDF'den metin çıkar
      final document = PdfDocument(inputBytes: bytes);
      final resumeText = PdfTextExtractor(document).extractText();
      document.dispose();

      if (resumeText.trim().isEmpty) {
        Fluttertoast.showToast(msg: "PDF içeriği boş ya da okunamıyor ❗");
        return;
      }

      // 3. Job description boşsa uyar
      if (jobDescription == null || jobDescription!.trim().isEmpty) {
        Fluttertoast.showToast(msg: "İlan açıklaması alınamadı ⚠");
        return;
      }

      // 4. Gemini ile analiz isteği at
      final analysis = await analyzeCV(
        resumeText: resumeText,
        jobDescription: jobDescription!,
      );

      if (analysis == null) {
        Fluttertoast.showToast(msg: "Gemini analizi başarısız oldu ❌");
        return;
      }

      // 5. Firestore'a başvuruyu kaydet
      await saveApplicationToFirestore(
        analysis['score'],
        analysis['reason'],
      );

      Fluttertoast.showToast(msg: "Başvuru başarıyla gönderildi ✅");
    } catch (e) {
      Fluttertoast.showToast(msg: "Hata oluştu: $e");
      print("CV başvuru hatası: $e");
    }
  }

  Future<Map<String, dynamic>?> analyzeCV({
    required String resumeText,
    required String jobDescription,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('http://192.168.1.46:3000/analyze-cv'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'resumeText': resumeText,
          'jobDesc': jobDescription,
        }),
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        print('Backend error: ${response.body}');
        return null;
      }
    } catch (e) {
      print('HTTP error: $e');
      return null;
    }
  }

  Future<void> saveApplicationToFirestore(int score, String reason) async {
    final uid = FirebaseAuth.instance.currentUser!.uid;

    // Firestore'dan kullanıcı bilgilerini al
    final userDoc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    final userData = userDoc.data();

    if (userData == null) {
      print("Kullanıcı bilgileri Firestore'da bulunamadı.");
      return;
    }

    final docRef =
        FirebaseFirestore.instance.collection('jobs').doc(widget.jobId);

    await docRef.update({
      'applications': FieldValue.arrayUnion([
        {
          'userId': uid,
          'userName': userData['name'] ?? 'Bilinmeyen',
          'userImageUrl': userData['imageUrl'] ?? '',
          'score': score,
          'reason': reason,
          'trustScore': userData['trustScore'] ?? 0,
          'trustReason': userData['trustReason'] ?? '',
          'timestamp': Timestamp.now(),
        }
      ]),
    });

    // Ayrıca "applicants" sayısını artır
    await docRef.update({'applicants': FieldValue.increment(1)});

    // Başvuran sayısını güncelle
    getJobData();
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
              icon: const Icon(
                Icons.close_outlined,
                size: 30,
                color: Colors.black,
              )),
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(4.0),
                child: Card(
                  color: Colors.black54,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(left: 4.0),
                          child: Text(
                            jobTitle == null ? '' : jobTitle!,
                            maxLines: 3,
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 30),
                          ),
                        ),
                        const SizedBox(
                          height: 20,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Container(
                              height: 60,
                              width: 60,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: Colors.grey,
                                  width: 3,
                                ),
                                shape: BoxShape.rectangle,
                                image: DecorationImage(
                                  fit: BoxFit.cover,
                                  image: NetworkImage(
                                    userImageUrl == null
                                        ? 'https://conceptwindows.com.au/wp-content/uploads/no-profile-pic-icon-27.png'
                                        : userImageUrl!,
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.only(left: 10.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(authorName == null ? '' : authorName!,
                                      style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16)),
                                  const SizedBox(
                                    height: 5,
                                  ),
                                  Text(location == null ? '' : location!,
                                      style: const TextStyle(
                                        color: Colors.grey,
                                      )),
                                ],
                              ),
                            )
                          ],
                        ),
                        dividerWidget(),
                        GestureDetector(
                          onTap: () {
                            if (FirebaseAuth.instance.currentUser?.uid ==
                                widget.uploadedBy) {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      ApplicantsListPage(jobId: widget.jobId),
                                ),
                              );
                            } else {
                              Fluttertoast.showToast(
                                msg: "Only the job poster can view applicants",
                                toastLength: Toast.LENGTH_LONG,
                                backgroundColor: Colors.grey,
                                fontSize: 18,
                                textColor: Colors.red[800],
                              );
                            }
                          },
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(applicants.toString(),
                                  style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 18)),
                              const SizedBox(
                                width: 6,
                              ),
                              const Text(
                                'Applicants ',
                                style: TextStyle(
                                    color: Colors.grey,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18),
                              ),
                              const SizedBox(
                                width: 10,
                              ),
                              const Icon(
                                Icons.how_to_reg_sharp,
                                color: Colors.grey,
                              )
                            ],
                          ),
                        ),
                        FirebaseAuth.instance.currentUser!.uid !=
                                widget.uploadedBy
                            ? Container()
                            : Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  dividerWidget(),
                                  const Text(
                                    'Recruitment',
                                    style: TextStyle(
                                        fontSize: 18,
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(
                                    height: 5,
                                  ),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      TextButton(
                                          onPressed: () {
                                            try {
                                              FirebaseFirestore.instance
                                                  .collection('jobs')
                                                  .doc(widget.jobId)
                                                  .update(
                                                      {'recruitment': true});
                                            } catch (e) {
                                              GlobalMethod.showErrorDialog(
                                                  error:
                                                      'This task cannot be performed',
                                                  ctx: context);
                                            }
                                            getJobData();
                                          },
                                          child: const Text('ON',
                                              style: TextStyle(
                                                  fontStyle: FontStyle.italic,
                                                  color: Colors.black,
                                                  fontSize: 18,
                                                  fontWeight:
                                                      FontWeight.normal))),
                                      Opacity(
                                        opacity: recruitment == true ? 1 : 0,
                                        child: const Icon(
                                          Icons.check_box,
                                          color: Colors.green,
                                        ),
                                      ),
                                      const SizedBox(
                                        width: 40,
                                      ),
                                      TextButton(
                                          onPressed: () {
                                            try {
                                              FirebaseFirestore.instance
                                                  .collection('jobs')
                                                  .doc(widget.jobId)
                                                  .update(
                                                      {'recruitment': false});
                                            } catch (e) {
                                              GlobalMethod.showErrorDialog(
                                                  error:
                                                      'This task cannot be performed',
                                                  ctx: context);
                                            }
                                            getJobData();
                                          },
                                          child: const Text('OFF',
                                              style: TextStyle(
                                                  fontStyle: FontStyle.italic,
                                                  color: Colors.black,
                                                  fontSize: 18,
                                                  fontWeight:
                                                      FontWeight.normal))),
                                      Opacity(
                                        opacity: recruitment == false ? 1 : 0,
                                        child: const Icon(
                                          Icons.check_box,
                                          color: Colors.red,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                        dividerWidget(),
                        const Text(
                          'Job Description',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        Text(
                          jobDescription == null ? '' : jobDescription!,
                          style:
                              const TextStyle(color: Colors.grey, fontSize: 14),
                          textAlign: TextAlign.justify,
                        ),
                        dividerWidget()
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(4.0),
                child: Card(
                  color: Colors.black54,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(
                          height: 5,
                        ),
                        Center(
                          child: Text(
                            isDeadlineAvailable
                                ? 'Actively Recruiting, Send CV/Resume'
                                : 'Deadline Passed away.',
                            style: TextStyle(
                                color: isDeadlineAvailable
                                    ? Colors.green
                                    : Colors.red,
                                fontSize: 17),
                          ),
                        ),
                        const SizedBox(
                          height: 15,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            if (FirebaseAuth.instance.currentUser?.uid !=
                                widget.uploadedBy)
                              MaterialButton(
                                onPressed: () {
                                  applyForJob();
                                },
                                color: Colors.black,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(13),
                                ),
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 14.0),
                                  child: Text(
                                    'Apply with Email',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16),
                                  ),
                                ),
                              ),
                            if (FirebaseAuth.instance.currentUser?.uid !=
                                widget.uploadedBy)
                              MaterialButton(
                                onPressed: () async {
                                  await selectAndSubmitCV();
                                },
                                color: Colors.black,
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(13),
                                ),
                                child: const Padding(
                                  padding: EdgeInsets.symmetric(vertical: 14.0),
                                  child: Text(
                                    'Apply with CV',
                                    style: TextStyle(
                                        color: Colors.white,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 16),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        dividerWidget(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Upload on: ',
                              style: TextStyle(
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              postedDate == null ? '' : postedDate!,
                              style: const TextStyle(
                                  color: Colors.grey,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15),
                            ),
                          ],
                        ),
                        const SizedBox(
                          height: 12,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Deadline at: ',
                              style: TextStyle(
                                color: Colors.white,
                              ),
                            ),
                            Text(
                              deadlineDate == null ? '' : deadlineDate!,
                              style: const TextStyle(
                                  color: Colors.grey,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15),
                            ),
                          ],
                        ),
                        dividerWidget()
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(4.0),
                child: Card(
                  color: Colors.black54,
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AnimatedSwitcher(
                          duration: Duration(milliseconds: 500),
                          child: _isCommenting
                              ? Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Flexible(
                                      flex: 3,
                                      child: TextField(
                                          controller: _commentController,
                                          cursorColor: Colors.blueAccent,
                                          style: TextStyle(color: Colors.white),
                                          maxLength: 200,
                                          keyboardType: TextInputType.text,
                                          maxLines: 6,
                                          decoration: InputDecoration(
                                            filled: true,
                                            fillColor: Theme.of(context)
                                                .scaffoldBackgroundColor,
                                            enabledBorder:
                                                const UnderlineInputBorder(
                                              borderSide: BorderSide(
                                                  color: Colors.white),
                                            ),
                                            focusedBorder:
                                                const OutlineInputBorder(
                                              borderSide: BorderSide(
                                                  color: Colors.white),
                                            ),
                                          )),
                                    ),
                                    Flexible(
                                        child: Column(
                                      children: [
                                        Padding(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8.0),
                                          child: MaterialButton(
                                            onPressed: () async {
                                              if (_commentController
                                                      .text.length <
                                                  7) {
                                                GlobalMethod.showErrorDialog(
                                                    error:
                                                        'Comment must be at least 7 characters long',
                                                    ctx: context);
                                              } else {
                                                final _generatedId =
                                                    Uuid().v4();

                                                DocumentSnapshot userDoc =
                                                    await FirebaseFirestore
                                                        .instance
                                                        .collection('users')
                                                        .doc(_auth
                                                            .currentUser!.uid)
                                                        .get();

                                                await FirebaseFirestore.instance
                                                    .collection('jobs')
                                                    .doc(widget.jobId)
                                                    .update({
                                                  'jobComments':
                                                      FieldValue.arrayUnion([
                                                    {
                                                      'userId': FirebaseAuth
                                                          .instance
                                                          .currentUser!
                                                          .uid,
                                                      'commentId': _generatedId,
                                                      'name':
                                                          userDoc.get('name'),
                                                      'userImageUrl': userDoc
                                                          .get('imageUrl'),
                                                      'commentBody':
                                                          _commentController
                                                              .text,
                                                      'time': Timestamp.now(),
                                                    }
                                                  ]),
                                                });
                                                await Fluttertoast.showToast(
                                                    msg: 'Comment Posted',
                                                    toastLength:
                                                        Toast.LENGTH_LONG,
                                                    backgroundColor:
                                                        Colors.grey,
                                                    fontSize: 18,
                                                    textColor:
                                                        Colors.green[800]);
                                                _commentController.clear();
                                              }
                                              setState(() {
                                                showComments = true;
                                              });
                                            },
                                            color: Colors.blueAccent,
                                            elevation: 0,
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: const Text('Post',
                                                style: TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16)),
                                          ),
                                        ),
                                        TextButton(
                                          onPressed: () {
                                            setState(() {
                                              _isCommenting = !_isCommenting;
                                              showComments = false;
                                            });
                                          },
                                          child: const Text('Cancel',
                                              style: TextStyle(
                                                  color: Colors.red,
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 16)),
                                        )
                                      ],
                                    )),
                                  ],
                                )
                              : Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    IconButton(
                                        onPressed: () {
                                          setState(() {
                                            _isCommenting = !_isCommenting;
                                          });
                                        },
                                        icon: const Icon(
                                          Icons.add_comment,
                                          color: Colors.blueAccent,
                                          size: 40,
                                        )),
                                    const SizedBox(
                                      width: 10,
                                    ),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: Colors.blueAccent,
                                        border: Border.all(
                                            color: Colors.blueAccent,
                                            width: 0.5),
                                        shape: BoxShape.circle,
                                      ),
                                      width: 40,
                                      height: 40,
                                      child: IconButton(
                                          onPressed: () {
                                            setState(() {
                                              showComments = !showComments;
                                            });
                                          },
                                          icon: Center(
                                            child: Icon(
                                              showComments
                                                  ? Icons.arrow_drop_up
                                                  : Icons.arrow_drop_down,
                                              color: Colors.black54,
                                            ),
                                          )),
                                    )
                                  ],
                                ),
                        ),
                        showComments == false
                            ? Container()
                            : Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: FutureBuilder(
                                    future: FirebaseFirestore.instance
                                        .collection('jobs')
                                        .doc(widget.jobId)
                                        .get(),
                                    builder: (context, snapshot) {
                                      if (snapshot.connectionState ==
                                          ConnectionState.waiting) {
                                        return const Center(
                                          child: CircularProgressIndicator(),
                                        );
                                      } else {
                                        if (snapshot.data == null) {
                                          return const Center(
                                            child: Text('No comments yet'),
                                          );
                                        }
                                      }
                                      return ListView.separated(
                                          shrinkWrap: true,
                                          physics:
                                              const NeverScrollableScrollPhysics(),
                                          itemBuilder: (context, index) {
                                            return CommentsWidget(
                                                commentId: snapshot
                                                        .data?['jobComments']
                                                    [index]['commentId'],
                                                commenterId:
                                                    snapshot.data?['jobComments']
                                                        [index]['userId'],
                                                commenterName:
                                                    snapshot.data?['jobComments']
                                                        [index]['name'],
                                                commentBody:
                                                    snapshot.data?['jobComments']
                                                        [index]['commentBody'],
                                                commenterImageUrl: snapshot
                                                        .data?['jobComments']
                                                    [index]['userImageUrl']);
                                          },
                                          separatorBuilder: (context, index) {
                                            return const Divider(
                                              thickness: 1,
                                              color: Colors.grey,
                                            );
                                          },
                                          itemCount: snapshot
                                              .data?['jobComments'].length);
                                    }),
                              )
                      ],
                    ),
                  ),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
