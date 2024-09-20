import 'package:apploja/model/usermodel.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';

class UserHomePage extends StatefulWidget {
  const UserHomePage({super.key});

  @override
  State<UserHomePage> createState() => _UserHomePageState();
}

class _UserHomePageState extends State<UserHomePage> {
  final _nameController = TextEditingController();
  final _cpfController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _searchController =
      TextEditingController(); // Controlador para o campo de pesquisa

  bool _editForm = false;
  String _editId = "";
  String _searchTerm = ""; // Termo de pesquisa

  final _formKey = GlobalKey<FormState>();

  // Máscaras
  var cpfMask = MaskTextInputFormatter(
      mask: '###.###.###-##', filter: {"#": RegExp(r'[0-9]')});
  var phoneMask = MaskTextInputFormatter(
      mask: '(##) #####-####', filter: {"#": RegExp(r'[0-9]')});

  // Função para validar e salvar usuário
  Future<void> _saveUser() async {
    if (_formKey.currentState!.validate()) {
      UserModel userModel = UserModel(
        name: _nameController.text,
        cpf: _cpfController.text,
        phone: _phoneController.text,
        email: _emailController.text,
      );

      if (_editForm) {
        // Atualizar usuário
        await FirebaseFirestore.instance
            .collection('users')
            .doc(_editId)
            .update(userModel.toJson());
        setState(() {
          _editForm = false;
          _editId = '';
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Usuário atualizado com sucesso!',
              style: TextStyle(color: Colors.black), // Texto preto
            ),
            backgroundColor:
                Color.fromARGB(255, 63, 247, 127), // Cor verde personalizada
          ),
        );
      } else {
        // Criar novo usuário
        final docRef = FirebaseFirestore.instance.collection('users').doc();
        await docRef.set(userModel.toJson());
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Usuário criado com sucesso!',
              style: TextStyle(color: Colors.black), // Texto preto
            ),
            backgroundColor:
                Color.fromARGB(255, 63, 247, 127), // Cor verde personalizada
          ),
        );
      }

      // Limpar campos após o envio
      _nameController.clear();
      _cpfController.clear();
      _phoneController.clear();
      _emailController.clear();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Por favor, preencha os campos corretamente.',
            style: TextStyle(color: Colors.white), // Texto branco para erro
          ),
          backgroundColor: Colors.red, // Cor vermelha para erros
        ),
      );
    }
  }

  // Função para editar o usuário
  void _editUser(UserModel userModel) {
    setState(() {
      _nameController.text = userModel.name;
      _cpfController.text = userModel.cpf;
      _phoneController.text = userModel.phone;
      _emailController.text = userModel.email;
      _editForm = true;
      _editId = userModel.id!;
    });
  }

  // Função para excluir usuário
  Future<void> _deleteUser(String userId) async {
    await FirebaseFirestore.instance.collection('users').doc(userId).delete();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Usuário excluído com sucesso!',
          style: TextStyle(color: Colors.black), // Texto preto
        ),
        backgroundColor:
            Color.fromARGB(255, 63, 247, 127), // Cor verde personalizada
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF5F5F5),
      appBar: AppBar(
        backgroundColor: const Color.fromARGB(255, 14, 105, 170),
        title: const Text(
          'Gerenciamento de Usuários',
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Cadastro de Usuário',
                style: TextStyle(
                    fontSize: 28.0,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF333333)),
              ),
              const SizedBox(height: 20.0),
              _buildTextField(_nameController, 'Nome', Icons.person, false),
              const SizedBox(height: 15.0),
              _buildTextField(_cpfController, 'CPF', Icons.credit_card, true,
                  maskFormatter: cpfMask),
              const SizedBox(height: 15.0),
              _buildTextField(_phoneController, 'Telefone', Icons.phone, true,
                  maskFormatter: phoneMask),
              const SizedBox(height: 15.0),
              _buildTextField(_emailController, 'Email', Icons.email, false,
                  isEmail: true),
              const SizedBox(height: 25.0),

              Center(
                child: ElevatedButton(
                  onPressed: _saveUser,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 14, 105, 170),
                    padding: const EdgeInsets.symmetric(
                        vertical: 16.0, horizontal: 20),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    _editForm ? 'Atualizar Usuário' : 'Cadastrar Usuário',
                    style: const TextStyle(fontSize: 18.0, color: Colors.white),
                  ),
                ),
              ),
              const SizedBox(height: 20.0),

              // Campo de pesquisa
              TextField(
                controller: _searchController,
                decoration: const InputDecoration(
                  labelText: 'Pesquisar por nome',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(),
                ),
                onChanged: (value) {
                  setState(() {
                    _searchTerm = value.toLowerCase();
                  });
                },
              ),
              const SizedBox(height: 20.0),

              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('users')
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    if (!snapshot.hasData) {
                      return const Text('Nenhum usuário encontrado.');
                    }

                    // Filtrar usuários pelo nome
                    final filteredUsers = snapshot.data!.docs.where((doc) {
                      final userModel = UserModel.fromDocument(doc);
                      return userModel.name.toLowerCase().contains(_searchTerm);
                    }).toList();

                    if (filteredUsers.isEmpty) {
                      return const Text(
                          'Nenhum usuário encontrado com esse nome.');
                    }

                    return ListView(
                      children: filteredUsers.map((doc) {
                        UserModel userModel = UserModel.fromDocument(doc);
                        return Card(
                          margin: const EdgeInsets.symmetric(vertical: 10.0),
                          elevation: 5,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Container(
                            decoration: const BoxDecoration(
                              borderRadius: BorderRadius.vertical(
                                bottom: Radius.circular(
                                    10), // Raio de 10 na parte inferior
                              ),
                              border: Border(
                                bottom: BorderSide(
                                  color: Color.fromARGB(255, 14, 105,
                                      170), // Cor da borda inferior
                                  width: 5.0, // Largura da borda
                                ),
                              ),
                            ),
                            child: ListTile(
                              title: Text(userModel.name,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold)),
                              subtitle: Text(
                                  'Email: ${userModel.email}\nTelefone: ${userModel.phone}\nCpf: ${userModel.cpf}',
                                  style: const TextStyle(color: Colors.grey)),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Container(
                                    margin: const EdgeInsets.only(right: 8.0),
                                    decoration: const BoxDecoration(
                                      color: Colors.yellow,
                                      shape: BoxShape.circle,
                                    ),
                                    child: IconButton(
                                      icon: const Icon(Icons.edit,
                                          color: Color(0xFF4A90E2)),
                                      onPressed: () => _editUser(userModel),
                                    ),
                                  ),
                                  Container(
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    child: IconButton(
                                      icon: const Icon(Icons.delete,
                                          color: Colors.white),
                                      onPressed: () =>
                                          _deleteUser(userModel.id!),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // Widget para simplificar os campos de texto
  Widget _buildTextField(TextEditingController controller, String labelText,
      IconData icon, bool isNumeric,
      {MaskTextInputFormatter? maskFormatter, bool isEmail = false}) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey.shade300, width: 1.0),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TextFormField(
        controller: controller,
        keyboardType: isNumeric ? TextInputType.number : TextInputType.text,
        inputFormatters: maskFormatter != null ? [maskFormatter] : [],
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: const Color(0xFF4A90E2)),
          labelText: labelText,
          labelStyle: const TextStyle(color: Color(0xFF333333)),
          border: InputBorder.none,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        ),
        validator: (value) {
          if (value == null || value.isEmpty) {
            return 'Campo obrigatório';
          }
          if (isEmail && !RegExp(r'^[^@]+@[^@]+\.[^@]+').hasMatch(value)) {
            return 'E-mail inválido';
          }
          return null;
        },
      ),
    );
  }
}
