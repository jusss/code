#include <stdio.h>
#include <stdlib.h>
#include <winsock.h>
#include <malloc.h>
#include <windows.h>
#include <string.h>
#include <time.h>
#include <io.h>
#include <errno.h>
#include <conio.h>
#pragma comment(lib,"ws2_32.lib")

main(m,l)
	char **l;
{
	
	WSADATA wsaData;	/* windows socket stuff */
	struct sockaddr_in serv_addr;	/* socket stuff */
	int retn0=0,retn1=0,sockfd0=0,retn2=0,retn3=0,nick_length=0,nick_lb=0;	/* nick_lb is nick length backup */
	
	extern int errno;	/* errno */
	char* sock_recv=NULL;
	char* keyboard=NULL;
	char nick[20]="0";

	fd_set fdset0;	/* select() stuff */
	struct timeval timeout;	/* select() stuff */
	
	WSAStartup(MAKEWORD(2,2),&wsaData);	/* windows socket init.. */
	sockfd0=socket(AF_INET,SOCK_STREAM,IPPROTO_TCP);
	serv_addr.sin_family=AF_INET;
	serv_addr.sin_addr.s_addr=inet_addr(*(l+1));
	serv_addr.sin_port=htons(60502);

	system("color 30");	/* call DOS API */
	system("title Client");
	system("cls");
	printf("Welcome to client??/n");

	sock_recv=(char *)malloc(10000);
	keyboard=(char *)malloc(10000);
	memset(keyboard,0,10000);
	memset(sock_recv,0,10000);
	write(1,"please input your nick:",23);
	nick_length=read(0,nick,20);	/* read() can read line feed */
	/* printf("%d",nick_length); */
	nick_lb = nick_length;
	
	if (nick_length > 20) {
		write(1,"too long nick..",15);
		goto exit;
	}
	nick[nick_length-1]=':';
	

	for (;nick_length>0;) {
		* (keyboard + nick_length-1) = nick[nick_length-1];
		--nick_length;
	}

	
	connect(sockfd0,(struct sockaddr*)&serv_addr,sizeof(serv_addr));
	
	for (;;) {

		FD_ZERO(&fdset0);
		FD_SET(sockfd0,&fdset0);	/* set monitor fd for select() */
		timeout.tv_sec=1;
		timeout.tv_usec=0;	/* set timeout for select() */
		
		retn3=select(sockfd0+1,&fdset0,NULL,NULL,&timeout);
		
		if (retn3<0) {perror("select");printf("%d??/n",errno);break;}
  
		if (FD_ISSET(sockfd0,&fdset0)) {
			memset(sock_recv,0,10000);
			retn1=recv(sockfd0,sock_recv,10000,0); /* retn1=read(sockfd0,sock_recv,10000); */
			if (retn1==-1) {perror("recv");printf("%d??/n",errno); break;}
			printf("%s",sock_recv);
			
		}

		if (kbhit()) {	/* linux's select(0+1,&fdset,NULL,NULL,&timeout);can monitor stdin,but ??/
win's select() can't monitor fd,only monitor socket,so use kbhit() monitor keyboard input */
 			memset(keyboard + nick_lb,0,10000-nick_lb);
			write(1,nick,nick_lb);
			retn0=read(0,keyboard + nick_lb,10000-nick_lb);
			if(retn0==-1) {perror("read");printf("%d??/n",errno);break;}
			send(sockfd0,keyboard,retn0 + nick_lb,0);
			
		}
		}	 
	
	closesocket(sockfd0);
	WSACleanup();

exit:
	
	getch();	/* wait for a key to input ,like pause */
	return 0;
}


	
	
	
