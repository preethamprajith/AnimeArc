
import 'package:animearc_admin/screens/login.dart';
import 'package:flutter/material.dart';

class Dashboard extends StatefulWidget {
  const Dashboard({super.key});

  @override
  State<Dashboard> createState() => _DashboardState();
}

class _DashboardState extends State<Dashboard> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 100.0),
            child: Row(
              children: [
                Icon(Icons.account_circle_outlined),
                SizedBox(width: 5),
                Text("Admin", style: TextStyle(),),
              ],
            ),
          ),
        ],
        title: Text("Dashboard"),
        backgroundColor:Color.fromARGB(255, 219, 117, 15) ,
      ),
      body: SingleChildScrollView(
        child: Row(
          children: [  
            Container(
              width: 300,
              height: 800,
              decoration: BoxDecoration(color: Color(0xfffaedcd)),
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Center(
                  child: Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ListTile
                        (onTap:(){ Navigator.push(context,  MaterialPageRoute(builder: (context)=>AdminLoginApp()),);},
                          leading: Icon(Icons.home),
                        title: Text('Home')),
                      ),
                  
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ListTile(onTap: (){ Navigator.push(context,  MaterialPageRoute(builder: (context)=>AdminLoginApp()),);},
                           leading: Icon(Icons.person),
                           title: Text('profile')),
                      ),
                  
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: ListTile(
                          onTap: () { Navigator.push(context,  MaterialPageRoute(builder: (context)=>AdminLoginApp()),);},
                           leading: Icon(Icons.settings),
                           title: Text('settings')),
                      ),
                  
                     Padding(
                        padding: const EdgeInsets.only(top: 370.0,left: 50),
                        child: ListTile(
                          onTap: () { Navigator.push(context,  MaterialPageRoute(builder: (context)=>AdminLoginApp()),);},
                           leading: Icon(Icons.power_settings_new_outlined),
                           title: Text('Log Out')),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Container(
              width:700,
              height: 700,
              decoration: BoxDecoration(color: Color(0xfffefae0)),
            )
          ], 
        ),
      ),
    );
  }
}