[![License](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Platform](https://img.shields.io/badge/platform-Windows%20Server-blue)]()
[![SQL Server](https://img.shields.io/badge/SQL%20Server-High%20Availability-success)]()

## 📖 Overview
>**SQL Server High Availability Group**

![](readme-images/SQLHAWithFC.jpg)

### Well, in any production environment, downtime is expensive — both in terms of money and user trust. SQL Server High Availability ensures that your database remains accessible, reliable, and resilient even if a server or component fails.

**The main benefits include:**

- Minimized Downtime: Your applications stay online even during hardware failures or maintenance.
- Automatic Failover: If one node fails, another takes over with minimal disruption.
- Data Protection: Keeps your data safe and synchronized across multiple nodes.
- Improved Performance: Some configurations allow for read-only replicas to handle reporting workloads.
- Compliance & SLA Readiness: Helps meet regulatory and business uptime requirements.

So essentially, HA ensures your SQL Server is always there when your application or users need it.

## ⚙️ Architecture
- **Platform**: Windows Server 2016+ 
- **Database**: SQL Server 2016+ 
- **Cloud**: Azure
- **Cloud Resources**:
  - Resource Groups
  - Virtual Networks (Primary and Secondary)
  - Public IPs
  - Virtual Machines
  - NSG (Network Security Groups)

## 📦 Setup Instructions
Here we will all the steps to perform this activity from beginning to end

> **Please Note:** Above mention application vm could be your any web or windows application server, but for simplicity, keeping another SQL server where from we will test other two SQL servers.

>### 1. Clone Repo and Open In VsCode
After cloning this repository locally, open in VSCode, open terminal mode, reach to folder "Terraform".
<img src= "readme-images/VSCode-terraform.jpg" alt="your-image-description" style="border: 2px solid grey;width:50%">

>### 2. Infra Setup By Terraform
Logging on the Azure portal and run all the terraform command (Assuming Terraform installed)
  - ``` az login ```
  - ``` az account set --subscription "xxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx" ```
  - ``` terraform init ```
  - ``` terraform plan -out sqlag.plan ```
  - ``` terraform apply sqlag.plan ```

>### 3. Verify all the Azure services
- As per this tutorial, two resource groups created "**rg-primary-sqlag-p-001**", "**rg-secondary-sqlag-p-001**"
- Two virtual networks (**vnet-primary** and **vnet-secondary**) created in each resource group and having vnet peering.
- Two network security groups (**nsg-primary** and **nsg-secondary**) created enabling 3389 inbound port on both NSGs.
- Three VMs (**applicationvm**, **localad** and **sqlvm-primary**) created in primary resource group and one VM (**sqlvm-secondary**) created in secondary.
- All four VMs having public IPs associated with them.

<img src= "readme-images/azure-resources-1.jpg" alt="your-image-description" style="border: 2px solid grey;width:50%">
<img src= "readme-images/azure-resources-2.jpg" alt="your-image-description" style="border: 2px solid grey;width:50%">
<img src= "readme-images/azure-resources-3.jpg" alt="your-image-description" style="border: 2px solid grey;width:50%">

>### 4. Setup localad as Domain Controller and Create Default user
> <span style="color:red"> Please Note that default credential of all 4 VMs is ***UsernName: adminuser*, *Password: P@ssw0rd123!***</span>

Install ADDS (Active Directory Domain Service) role and promote server as domain controller with new forest "**sqlag.local**" with password "P@ssw0rd123!". Rest click next with default settings and install.

<img src= "readme-images/localad-1.jpg" alt="your-image-description" style="border: 2px solid grey;width:50%">
<img src= "readme-images/localad-2.jpg" alt="your-image-description" style="border: 2px solid grey;width:50%">
<img src= "readme-images/localad-3.jpg" alt="your-image-description" style="border: 2px solid grey;width:50%">
<img src= "readme-images/localad-4.jpg" alt="your-image-description" style="border: 2px solid grey;width:50%">
<img src= "readme-images/localad-5.jpg" alt="your-image-description" style="border: 2px solid grey;width:50%">

>### 5. Update DNS Server in Azure Virtual Network
Copy private IP of DNS server and update in virtual network DNS.

<img src= "readme-images/update-dns-1.jpg" alt="your-image-description" style="border: 2px solid grey;width:50%">

<img src= "readme-images/update-dns-2.jpg" alt="your-image-description" style="border: 2px solid grey;width:30%">

<img src= "readme-images/update-dns-3.jpg" alt="your-image-description" style="border: 2px solid grey;width:30%">

>### 6. Login all three VMs and update to SQL Authentication Mode
As by default, rest three servers (applicationvm, sqlvm-primary and sqlvm-secondary) having SQL server VMs with windows authentication mode. Update all three VMs to SQL Authentication mode and enabled the "sa" login. Restart the SQL Services from the configuration.

<img src= "readme-images/sql-auth-update-1.jpg" alt="your-image-description" style="border: 2px solid grey;width:50%">
<img src= "readme-images/sql-auth-update-2.jpg" alt="your-image-description" style="border: 2px solid grey;width:50%">
<img src= "readme-images/sql-auth-update-3.jpg" alt="your-image-description" style="border: 2px solid grey;width:50%">
<img src= "readme-images/sql-auth-update-4.jpg" alt="your-image-description" style="border: 2px solid grey;width:50%">

>### 7. Update DNS server in all three VMs by "ipconfig /renew"
By default Azure VM is on default DNS server, which we need to renew by the command ``` ipconfig /renew ``` and check the same by another command ``` ipconfig /all ```

<img src= "readme-images/vm-dns-join-1.jpg" alt="your-image-description" style="border: 2px solid grey;width:50%">
<img src= "readme-images/vm-dns-join-2.jpg" alt="your-image-description" style="border: 2px solid grey;width:50%">

>### 8. Update all three VMs workgroup to local domain.

<img src= "readme-images/vm-dns-join-3.jpg" alt="your-image-description" style="border: 2px solid grey;width:50%">

>Now open the VM by domain controller user.

<img src= "readme-images/vm-dns-join-4.jpg" alt="your-image-description" style="border: 2px solid grey;width:50%">

>### 9. Install and Setup the failover cluster
In both the SQL server VMs (sqlvm-primary and sqlvm-secondary), install the failover cluster and setup as per the below diagrams. During setup the failover cluster, we need to add both VMs by their hostname and choose default for all settings.

<img src= "readme-images/setup-failover-cluster-1.jpg" alt="your-image-description" style="border: 2px solid grey;width:50%">
<img src= "readme-images/setup-failover-cluster-2.jpg" alt="your-image-description" style="border: 2px solid grey;width:50%">
<img src= "readme-images/setup-failover-cluster-3.jpg" alt="your-image-description" style="border: 2px solid grey;width:50%">
<img src= "readme-images/setup-failover-cluster-4.jpg" alt="your-image-description" style="border: 2px solid grey;width:50%">
<img src= "readme-images/setup-failover-cluster-5.jpg" alt="your-image-description" style="border: 2px solid grey;width:50%">
<img src= "readme-images/setup-failover-cluster-6.jpg" alt="your-image-description" style="border: 2px solid grey;width:50%">


> **Need to update cluster IP as per the free IP available in subnet**

<img src= "readme-images/setup-failover-cluster-7.jpg" alt="your-image-description" style="border: 2px solid grey;width:50%">
<img src= "readme-images/setup-failover-cluster-8.jpg" alt="your-image-description" style="border: 2px solid grey;width:50%">
<img src= "readme-images/setup-failover-cluster-9.jpg" alt="your-image-description" style="border: 2px solid grey;width:50%">

>### 10. Setup SQL Server High availability
Now need to turn on the high availability in both SQL servers and switch log on account to domain name.

<img src= "readme-images/sql-account-update-1.jpg" alt="your-image-description" style="border: 2px solid grey;width:20%">

<img src= "readme-images/sql-account-update-2.jpg" alt="your-image-description" style="border: 2px solid grey;width:20%">

<img src= "readme-images/sql-account-update-3.jpg" alt="your-image-description" style="border: 2px solid grey;width:20%">

>### 11. Download Sample DB (Adventure Works) in primary server
You can download the [sample DB](https://learn.microsoft.com/en-us/sql/samples/adventureworks-install-configure?view=sql-server-ver16&tabs=ssms) from here. Restore the DB, Change recovery mode to Full and take full backup.

<img src= "readme-images/DB-Setup-1.jpg" alt="your-image-description" style="border: 2px solid grey;width:40%">

<img src= "readme-images/DB-Setup-2.jpg" alt="your-image-description" style="border: 2px solid grey;width:40%">

<img src= "readme-images/DB-Setup-3.jpg" alt="your-image-description" style="border: 2px solid grey;width:40%">

<img src= "readme-images/DB-Setup-4.jpg" alt="your-image-description" style="border: 2px solid grey;width:40%">

<img src= "readme-images/DB-Setup-5.jpg" alt="your-image-description" style="border: 2px solid grey;width:40%">

>### 12. Update the firewall rules in both SQL Servers VMs
Add the inbound firewall rule to allow Port 1433 and 5022 in both servers.

<img src= "readme-images/update-firewall-1.jpg" alt="your-image-description" style="border: 2px solid grey;width:40%">

<img src= "readme-images/update-firewall-2.jpg" alt="your-image-description" style="border: 2px solid grey;width:40%">

<img src= "readme-images/update-firewall-3.jpg" alt="your-image-description" style="border: 2px solid grey;width:40%">

>### 13. Create and Setup the availability group
In this setup, we will add both sql servers as replica. If we want to setup both SQL servers as high Availability then we will choose "Synchronous Commit" else if we want to setup DR (disaster Recover) then we will choose "Asynchronous commit".

<img src= "readme-images/setup-availability-1.jpg" alt="your-image-description" style="border: 2px solid grey;width:30%">
<img src= "readme-images/setup-availability-2.jpg" alt="your-image-description" style="border: 2px solid grey;width:30%">
<img src= "readme-images/setup-availability-3.jpg" alt="your-image-description" style="border: 2px solid grey;width:30%">
<img src= "readme-images/setup-availability-4.jpg" alt="your-image-description" style="border: 2px solid grey;width:30%">
<img src= "readme-images/setup-availability-5.jpg" alt="your-image-description" style="border: 2px solid grey;width:30%">

#### Remember while setting up the SQL server listener, we will again provide two more free IPs from both the subnets.**

<img src= "readme-images/setup-availability-6.jpg" alt="your-image-description" style="border: 2px solid grey;width:60%">

#### Finally both servers will show AdventureWorks DB as synchronized.

<img src= "readme-images/setup-availability-7.jpg" alt="your-image-description" style="border: 2px solid grey;width:30%">

<img src= "readme-images/setup-availability-8.jpg" alt="your-image-description" style="border: 2px solid grey;width:30%">
<img src= "readme-images/setup-availability-9.jpg" alt="your-image-description" style="border: 2px solid grey;width:30%">

#### **Remember Secondary SQL server DB working as Read-Only DB.**
<img src= "readme-images/setup-availability-10.jpg" alt="your-image-description" style="border: 2px solid grey;width:20%">
<img src= "readme-images/setup-availability-11.jpg" alt="your-image-description" style="border: 2px solid grey;width:20%">

#### Attach the listener IPs into the SQL servers NIC cards

<img src= "readme-images/Update-listener-ip-1.jpg" alt="your-image-description" style="border: 2px solid grey;width:50%">
<img src= "readme-images/Update-listener-ip-2.jpg" alt="your-image-description" style="border: 2px solid grey;width:50%">

>### 14. Test the Failover

Lets try to update one of the table from the"**Application VM**" by connecting the listener **"sqlag-listener"** and now verify the same on both SQL servers and you will find the updated record.

<img src= "readme-images/test-failover-1.jpg" alt="your-image-description" style="border: 2px solid grey;width:50%">
<img src= "readme-images/test-failover-2.jpg" alt="your-image-description" style="border: 2px solid grey;width:50%">
<img src= "readme-images/test-failover-3.jpg" alt="your-image-description" style="border: 2px solid grey;width:50%">

> Now Lets stop the Primary SQL server and update the record from the Application server and verify from the secondary SQL server. You will also find that secondary server become the primary and Read/Write DB.

<img src= "readme-images/test-failover-4.jpg" alt="your-image-description" style="border: 2px solid grey;width:50%">
<img src= "readme-images/test-failover-5.jpg" alt="your-image-description" style="border: 2px solid grey;width:50%">
<img src= "readme-images/test-failover-6.jpg" alt="your-image-description" style="border: 2px solid grey;width:50%">

> Now Lets start the PrimarySQL Server and stop the secondary SQL server and update the record from the application server and verify again.

<img src= "readme-images/test-failover-7.jpg" alt="your-image-description" style="border: 2px solid grey;width:50%">
<img src= "readme-images/test-failover-8.jpg" alt="your-image-description" style="border: 2px solid grey;width:50%">
<img src= "readme-images/test-failover-9.jpg" alt="your-image-description" style="border: 2px solid grey;width:50%">

---
# 🎉 Completion Note
**Hurrah!**

If you’ve made it this far, congratulations — you’ve successfully configured the SQL Server High Availability Group on a Windows Failover Cluster.

Thanks for your patience and persistence throughout the process!


# 📚 Resources
- [Microsoft Docs: SQL Server AG](https://learn.microsoft.com/en-us/sql/database-engine/availability-groups/windows/overview-of-always-on-availability-groups-sql-server?view=sql-server-ver16)

- [WSFC Guide](https://learn.microsoft.com/en-us/sql/sql-server/failover-clusters/windows/windows-server-failover-clustering-wsfc-with-sql-server?view=sql-server-ver16)


