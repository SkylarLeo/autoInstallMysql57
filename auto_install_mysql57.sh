#!/bin/bash

InstallPrep() {
	# 下载mysql57最新版rpm包
	echo "-------------------->Start Download Mysql_RPM<--------------------"
	curl -S -O http://repo.mysql.com/mysql57-community-release-el7-10.noarch.rpm

	# 安装 rpm 源
	echo "-------------------->Start Installing Mysql_RPM<--------------------"
	rpm -Uvh mysql57-community-release-el7-10.noarch.rpm&>/dev/null

	# 安装 mysql 
	yum -y install mysql-community-server 

	if [ $? -ne 0 ]; then
		if [ $? -eq 1 ]; then 
			# 如果上一步的状态码不为 0 则执行出现错误，一般错误为密钥无法使用
			rpm --import https://repo.mysql.com/RPM-GPG-KEY-mysql-2022
			rpm -Uvh mysql57-community-release-el7-10.noarch.rpm&>/dev/null
			if [ $? -ne 0 ]; then
				echo "An unknown error occurred"
				exit 1
			fi
		else
			echo "The error occurred not on the key"
			exit 1
		fi
	fi

	systemctl start mysqld.service
	rm -rf ./mysql57-community-release-el7-10.noarch.rpm	
	echo "Mysql 启动成功"
}

SetBasic() {
	# 查看安装后随机生成的 mysql root 密码
	DefaultPasswd=`grep 'temporary password' /var/log/mysqld.log | sed 's|^.*:.\(.*\)|\1|g'`

	# 登录 mysql
	expect <<EOF
	spawn mysql -u root -p
	expect "Enter password:"
	send "${DefaultPasswd}\r"
	expect {
		"ERROR 1045 (28000): Access denied for user 'root'@'localhost' (using password: YES)" {
			# 如果发生错误则提示用户确认
			send_user "Passwd Error!!!!"
			exit 1
		}
		"mysql>" {
			send "set global validate_password_policy=0;\r"
			expect "mysql>"
			send "set global validate_password_length=1;\r"
			expect "mysql>"
			send "ALTER USER 'root'@'localhost' IDENTIFIED BY 'admin2023..';\r"
			expect "mysql>"
		}
		send "quit\r"
		expect eof
	}
EOF
	printf "Mysql basic configuration has been completed, open external IP access please use \nGRANT ALL PRIVILEGES ON *.* TO 'root'@'%' IDENTIFIED BY 'yourpassword' WITH GRANT OPTION; \nand execute FLUSH PRIVILEGES;\n"
}


TestMysqlIs() {

# 测试是否已经安装 mysql
	mysql --version&>/dev/null 
	if [ $? -eq 0 ]; then 
		echo "Mysql installed"
		printf "Do you want to continue configuring mysql(y|N)? "
		read -r answer
		case answer in
		y|Y)
			expecta -v&>/dev/null
			if [ $? -ne 0 ];then
				yum -y install expect&>/dev/null
			fi
			SetBasic	
			return 0
		;;
		n|N)
			return 1
		;;
		*)
			return 1
		;;
		esac
	fi
}

main() {
	echo "-------------------->start configuration<--------------------"
	TestMysqlIs
	echo "-------------------->end configuration<--------------------"
	if [ $? -eq 0 ];then
		echo "-------------------->Start installing mysql<--------------------"
		InstallPrep	
		echo "-------------------->Mysql Deafulat Passwd is admin2023..<--------------------"
	fi
	
	echo "-------------------->mysql installed<--------------------"
	echo "-------------------->Thanks Use~~~~<--------------------"
}

main
