# Accessing CABI cluster

**Creating a cluster account**

1. To create a CABI Linux account, follow this [link](http://www.cabi.gatech.edu/CABI/cabi_information/research-2/forms/linux/) and submit the request form.
2. You will receive an email shortly, confirming that your CABI cluster account has been created.

**Accessing the cluster and running computations**

1. You can access the cluster either by logging in to any workstation locally at the CABI cluster computer room or by connecting remotely.
2. All the raw fMRI data will be stored in the cluster (under Doby&#39;s account). Use your cluster account for accessing and analyzing your data.
3. To access the cluster remotely from a terminal:
  1. Type &#39;ssh [username@ssh.cabi.gatech.edu](mailto:username@ssh.cabi.gatech.edu)&#39;
  2. Enter your password
4. Alternatively, to get the remote access software, download FastX (highly recommended) but first contact Vishwadeep Ahluwalia, ([vahluwalia7@gatech.edu](mailto:vahluwalia7@gatech.edu)) and he will explain the process since we are currently in transition from another software (Oct 2020).
5. **Do not run any programs directly on the systems you connect to**. To run computations, please connect to other CABI cpus (cpu164 - cpu171):
  1. Open the terminal
  2. Type &#39;ssh -Y cpu169&#39;
  3. Enter your password
  4. When you see [username@cpu169~]$  appear on the screen, proceed to run your programs for computation (E.g. matlab)

**Remotely access to the cluster on your device

1. Install and run FastX3(https://www.starnet.com/fastx/trynow.php) on your personal system. You need to sign up to get a download link.
2. Once the program launched, press '+' button on the left top corner of the window to add a connection.
3. Select 'ssh' as your type of connection. Enter the host name: ssh.cabi.gatech.edu
4. Use username that you set for the cluster account.
5. You can use any name for the name section (e.g., CABI Cluster).
6. Click 'Ok' will list your connection.
7. Make sure to connect your personal device to the campus IP through VPN if you are out of campus.
8. Double clik the created connection and select 'Open' and enter your CABI account password in the pop-up window. 
9. Click '+' sign on the left top corner of the window and select the type of linux desktop manager (I usually use 'XFCE').
10. Click 'Ok' and your linux home screen should pop up.   

**Transferring files between your cluster account and personal system**

1. Install and run [Cyberduck](https://cyberduck.io/download/) on your personal system
2. Connect to the campus IP using VPN if you are not connected to GT wifi
3. Open a new Connection (button on the left hand corner)
4. Select SFTP (SSH file transfer protocol) from the drop down menu
5. Enter the server name: cabi.gatech.edu
6. Enter your login details
7. Connect
8. Drag and drop files to transfer them

_Note: These instructions are for Cyberduck version 7.6.1_
