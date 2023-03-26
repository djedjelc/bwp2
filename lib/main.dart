import 'dart:io';
import 'package:biowinpharma_test/page_du_site.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
// Amplify Flutter Packages
import 'package:amplify_flutter/amplify_flutter.dart';
import 'package:amplify_auth_cognito/amplify_auth_cognito.dart';

import 'amplifyconfiguration.dart';
import 'package:amplify_storage_s3/amplify_storage_s3.dart';
import 'package:path_provider/path_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const MaterialApp(
    home: MyApp(),
  ));
}

Future<void> _configureAmplify() async {
  try {
    final auth = AmplifyAuthCognito();
    final storage = AmplifyStorageS3();
    await Amplify.addPlugins([auth, storage]);

    // call Amplify.configure to use the initialized categories in your app
    await Amplify.configure(amplifyconfig);
  } on Exception catch (e) {
    safePrint('An error occurred configuring Amplify: $e');
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  // ignore: library_private_types_in_public_api
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  File? imageFile;
  final picker = ImagePicker();
  final _formKey = GlobalKey<FormState>();

  bool _isLoading = false;

  String? phone;

  Future pickImage() async {
    // ignore: deprecated_member_use
    final pickedFile = await picker.getImage(
      source: ImageSource.gallery,
    );

    setState(() {
      if (pickedFile != null) {
        imageFile = File(pickedFile.path);
      }
    });
  }

  Future takePicture() async {
    // ignore: deprecated_member_use
    final pickedFile = await picker.getImage(
      source: ImageSource.camera,
    );

    setState(() {
      if (pickedFile != null) {
        imageFile = File(pickedFile.path);
      }
    });
  }

  Future uploadImage() async {
    if (imageFile == null) {
      return;
    }

    // Get the temporary directory
    final tempDir = await getTemporaryDirectory();

    // Create a file object from the selected image
    final selectedFile = File(imageFile!.path);

    // Create a temporary file with a unique name
    final tempFile = File(
        '${tempDir.path}/${DateTime.now().millisecondsSinceEpoch.toString()}.png');

    // Copy the selected image to the temporary file
    await selectedFile.copy(tempFile.path);

    // Upload the file to S3
    try {
      final UploadFileResult result = await Amplify.Storage.uploadFile(
        local: tempFile,
        key:
            'prescription_${phone}_${_deliveryOption}_${DateTime.now().millisecondsSinceEpoch.toString()}.png',
        options: S3UploadFileOptions(accessLevel: StorageAccessLevel.guest),
        onProgress: (progress) {
          print('Fraction completed: ${progress.getFractionCompleted()}');
        },
      );
      print('Successfully uploaded file: ${result.key}');
    } catch (e) {
      print('Error uploading file: $e');
    }

    // Delete the temporary file
    tempFile.deleteSync();
  }

  void submitData() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    phone = phoneController.text.trim();

    await uploadImage();

    nameController.clear();
    emailController.clear();
    phoneController.clear();
    setState(() {
      imageFile = null;
      _isLoading = false;
    });

    // Afficher un SnackBar de confirmation
    // ignore: use_build_context_synchronously
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Ordonnance envoyée avec succès !'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    _configureAmplify();
  }

  Color couleur1 = const Color(0xFFEA2430);
  Color couleur2 = const Color(0xFF2182C1);

  bool _deliveryOption = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color.fromARGB(58, 255, 255, 255),
              Color.fromARGB(96, 244, 67, 54)
            ],
          ),
        ),
        child: SingleChildScrollView(
          child: Container(
            padding: const EdgeInsets.all(20),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  const SizedBox(height: 60),
                  Image.asset('assets/logo.jpeg'),
                  const SizedBox(height: 20),
                  const Text(
                    "Vous pouvez envoyer votre ordonnance pour consultation",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                    ),
                  ),
                  const SizedBox(height: 10),
                  if (imageFile != null)
                    Image.file(
                      imageFile!,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  const SizedBox(height: 35),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton.icon(
                        onPressed: pickImage,
                        icon: const Icon(Icons.image),
                        label: const Text('Galerie'),
                        style:
                            ElevatedButton.styleFrom(backgroundColor: couleur2),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton.icon(
                        onPressed: takePicture,
                        icon: const Icon(Icons.camera),
                        label: const Text('Caméra'),
                        style:
                            ElevatedButton.styleFrom(backgroundColor: couleur2),
                      ),
                    ],
                  ),

                  // Téléphone
                  const SizedBox(height: 40),
                  TextFormField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(
                      labelText: 'Numéro de téléphone*',
                      prefix: Text('+223 '),
                      border: OutlineInputBorder(),
                    ),
                    validator: (value) {
                      if (value!.isEmpty) {
                        return 'Veuillez entrer votre numéro de téléphone';
                      }
                      if (!RegExp(r'^\+?[0-9]+$').hasMatch(value)) {
                        return 'Veuillez entrer un numéro de téléphone valide';
                      }
                      if (!RegExp(r'^[0-9]{8}$').hasMatch(value)) {
                        return 'Votre numéro doit comporté 08 chiffres';
                      }
                      return null;
                    },
                  ),

                  // Livraison
                  const SizedBox(height: 30),
                  const Text(
                    'Si vous voulez être livré, cliquez sur OUI',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                    ),
                  ),

                  Image.asset('assets/delivery.png'),

                  CheckboxListTile(
                    title: const Text(
                      'OUI',
                      style: TextStyle(
                        fontSize: 20,
                      ),
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                    value: _deliveryOption,
                    onChanged: (bool? value) {
                      setState(() {
                        _deliveryOption = value ?? false;
                      });
                    },
                  ),

                  // Bouton
                  const SizedBox(height: 35),
                  ElevatedButton(
                    onPressed: () async {
                      if (imageFile == null) {
                        // Afficher une boîte de dialogue pour informer l'utilisateur
                        await showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: const Text("Image obligatoire"),
                            content: const Text(
                                "Veuillez sélectionner une image avant de soumettre le formulaire."),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text("OK"),
                              ),
                            ],
                          ),
                        );
                        return;
                      }
                      // L'utilisateur a sélectionné une image, appeler la fonction submitData
                      submitData();
                    },
                    style: ElevatedButton.styleFrom(
                        backgroundColor: couleur1,
                        padding: const EdgeInsets.all(12)),
                    child: _isLoading
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            'Envoyer l\'ordonnance',
                            style: TextStyle(fontSize: 18),
                          ),
                  ),
                  const SizedBox(height: 40),
                  InkWell(
                    child: Text(
                      'Plus d\'options',
                      style: TextStyle(
                        fontSize: 18,
                        color: Colors.black,
                        fontWeight: FontWeight.bold
                      ),
                    ),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => PageDuSite()),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
