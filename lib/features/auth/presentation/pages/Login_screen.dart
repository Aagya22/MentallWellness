import 'package:flutter/material.dart';
import 'package:mentalwellness/common/mysnack_bar.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();

  bool _rememberMe = false;
  bool _isPasswordVisible = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 30),
                Center(
                  child: Image.asset(
                    "assets/images/novacane.png",
                    height: 90,
                  ),
                ),
                const SizedBox(height: 30),
                const Text("Welcome back",
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
                const SizedBox(height: 6),
                const Text("sign in to access your account",
                    style: TextStyle(fontSize: 14, color: Colors.grey)),
                const SizedBox(height: 30),
                TextFormField(
                  controller: _emailController,
                  decoration: InputDecoration(
                    hintText: "Enter your email",
                    filled: true,
                    fillColor: const Color(0xffEFEDE7),
                    suffixIcon: const Icon(Icons.email_outlined),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Email is required";
                    }
                    if (!value.contains("@")) {
                      return "Enter a valid email";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 15),
                TextFormField(
                  controller: _passwordController,
                  obscureText: !_isPasswordVisible,
                  decoration: InputDecoration(
                    hintText: "Password",
                    filled: true,
                    fillColor: const Color(0xffEFEDE7),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _isPasswordVisible
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                      onPressed: () {
                        setState(() {
                          _isPasswordVisible = !_isPasswordVisible;
                        });
                      },
                    ),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide.none),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return "Password is required";
                    }
                    if (value.length < 6) {
                      return "Password must be at least 6 characters";
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 10),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Checkbox(
                          value: _rememberMe,
                          onChanged: (v) {
                            setState(() {
                              _rememberMe = v!;
                            });
                          },
                        ),
                        const Text("Remember me", style: TextStyle(fontSize: 13)),
                      ],
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pushNamed(context, '/ForgotpasswordScreen');
                      },
                      child: const Text("Forgot password ?",
                          style: TextStyle(fontSize: 13, color: Colors.red)),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: 160,
                  height: 48,
                  child: ElevatedButton(
                    // style: ElevatedButton.styleFrom(
                    //   backgroundColor: Colors.green.shade900,
                    //   foregroundColor: Colors.white,
                    //   shape: RoundedRectangleBorder(
                    //       borderRadius: BorderRadius.circular(8)),
                    // ),
                    onPressed: () {
                      if (_formKey.currentState!.validate()) {
                        if (_rememberMe) {
                          showMySnackBar(
                              context: context,
                              message: "Remember me selected",
                              color: Colors.orange);
                        }
                        showMySnackBar(
                            context: context,
                            message: "Login Successful",
                            color: Colors.green);
                        Navigator.pushReplacementNamed(
                            context, '/BottomNavigationScreen');
                      } else {
                        showMySnackBar(
                            context: context,
                            message: "Please fill all required fields",
                            color: Colors.red);
                      }
                    },
                    child: const Text("Login", style: TextStyle(fontSize: 16)),
                  ),
                ),
                const SizedBox(height: 30),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text("New member ? "),
                    GestureDetector(
                      onTap: () {
                        Navigator.pushNamed(context, '/RegisterScreen');
                      },
                      child: const Text("Register now",
                          style: TextStyle(
                              color: Colors.red, fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
