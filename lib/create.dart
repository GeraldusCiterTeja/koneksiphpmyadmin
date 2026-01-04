import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class CreateProductPage extends StatefulWidget {
  final dynamic product; // ⬅️ untuk EDIT

  const CreateProductPage({super.key, this.product});

  @override
  State<CreateProductPage> createState() => _CreateProductPageState();
}

class _CreateProductPageState extends State<CreateProductPage> {
  final TextEditingController _nameController = TextEditingController();

  File? _image;               // Android
  Uint8List? _webImage;       // Web
  XFile? _pickedFile;

  bool isLoading = false;
  final picker = ImagePicker();

  bool get isEdit => widget.product != null;

  /// 🔹 CREATE / UPDATE API
  String get apiUrl {
    return kIsWeb
        ? isEdit
            ? 'http://127.0.0.1/apiflutter/update.php'
            : 'http://127.0.0.1/apiflutter/create.php'
        : isEdit
            ? 'http://10.0.2.2/apiflutter/update.php'
            : 'http://10.0.2.2/apiflutter/create.php';
  }

  /// 🔹 IMAGE URL (preview lama saat edit)
  String imageUrl(String photo) {
    return kIsWeb
        ? 'http://127.0.0.1/apiflutter/uploads/$photo'
        : 'http://10.0.2.2/apiflutter/uploads/$photo';
  }

  @override
  void initState() {
    super.initState();

    /// 🔸 SET DATA SAAT EDIT
    if (isEdit) {
      _nameController.text = widget.product['nama'];
    }
  }

  Future<void> pickImage() async {
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      if (kIsWeb) {
        _webImage = await picked.readAsBytes();
        _pickedFile = picked;
      } else {
        _image = File(picked.path);
      }
      setState(() {});
    }
  }

  Future<void> submitProduct() async {
    if (_nameController.text.isEmpty) {
      _showSnackBar('Nama wajib diisi', Colors.orange);
      return;
    }

    setState(() => isLoading = true);

    try {
      var request = http.MultipartRequest(
        'POST',
        Uri.parse(apiUrl),
      );

      request.fields['nama'] = _nameController.text;

      /// 🔸 KIRIM ID SAAT EDIT
      if (isEdit) {
        request.fields['id'] = widget.product['id'].toString();
      }

      /// 🔸 FOTO BARU (OPSIONAL SAAT EDIT)
      if (kIsWeb && _webImage != null) {
        request.files.add(
          http.MultipartFile.fromBytes(
            'photo',
            _webImage!,
            filename: _pickedFile!.name,
          ),
        );
      } else if (!kIsWeb && _image != null) {
        request.files.add(
          await http.MultipartFile.fromPath('photo', _image!.path),
        );
      }

      var response = await request.send();

      if (!mounted) return;

      if (response.statusCode == 200) {
        Navigator.pop(context, true);
      } else {
        _showSnackBar('Gagal menyimpan data', Colors.red);
      }
    } catch (e) {
      _showSnackBar('Error: $e', Colors.red);
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Product' : 'Add Product'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            /// NAMA
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Product Name',
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            /// FOTO
            GestureDetector(
              onTap: pickImage,
              child: Container(
                height: 180,
                width: double.infinity,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _buildImagePreview(),
              ),
            ),

            const SizedBox(height: 24),

            /// BUTTON
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: isLoading ? null : submitProduct,
                child: isLoading
                    ? const CircularProgressIndicator(color: Colors.white)
                    : Text(isEdit ? 'UPDATE' : 'SAVE'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 🖼 PREVIEW FOTO
  Widget _buildImagePreview() {
    /// FOTO BARU
    if (kIsWeb && _webImage != null) {
      return Image.memory(_webImage!, fit: BoxFit.cover);
    } else if (!kIsWeb && _image != null) {
      return Image.file(_image!, fit: BoxFit.cover);
    }

    /// FOTO LAMA (EDIT)
    if (isEdit) {
      return Image.network(
        imageUrl(widget.product['photo']),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) =>
            const Center(child: Icon(Icons.broken_image)),
      );
    }

    return const Center(child: Text('Tap to select image'));
  }
}
