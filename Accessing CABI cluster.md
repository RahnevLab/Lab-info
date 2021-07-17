# Accessing CABI cluster

**Creating a cluster account**

1. To create a CABI Linux account, follow this [link](http://www.cabi.gatech.edu/CABI/cabi_information/research-2/forms/linux/) and submit the request form.
2. You will receive an email shortly, confirming that your CABI cluster account has been created.

**Accessing the cluster and running computations**

1. You can access the cluster either by logging in to any workstation locally at the CABI cluster computer room or by connecting remotely.
2. All the raw fMRI data will be stored in the cluster (under Doby&#39;s account). Use your cluster account for accessing and analyzing your data.
3. To access the cluster remotely from a terminal:
  1. Type &#39;ssh [username@cabi.gatech.edu](mailto:username@cabi.gatech.edu)&#39;
  2. Enter your password
4. Alternatively, to get the remote access software, download FastX (highly recommended) but first contact Vishwadeep Ahluwalia, ([vahluwalia7@gatech.edu](mailto:vahluwalia7@gatech.edu)) and he will explain the process since we are currently in transition from another software (Oct 2020).
5. **Do not run any programs directly on the systems you connect to**. To run computations, please connect to other CABI cpus (cpu164 - cpu171):
  1. Open the terminal
  2. Type &#39;ssh -Y cpu169&#39;
  3. Enter your password
  4. When you see [username@cpu169~]$  appear on the screen, proceed to run your programs for computation (E.g. matlab)

**Transferring files between your cluster account and personal system**

1. Install and run [Cyberduck](https://cyberduck.io/download/) on your personal system
2. Open a new Connection (button on the left hand corner)
3. Select SFTP (SSH file transfer protocol) from the drop down menu
4. Enter the server name: cabiatl.com
5. Enter your login details
6. Connect
7. Drag and drop files to transfer them

_Note: These instructions are for Cyberduck version 7.6.1_
