#include <stdio.h>
#include <stdlib.h>
#include <winsock.h>
#include <malloc.h>
#include <windows.h>
#include <string.h>
#include <time.h>
#include <io.h>
#include <conio.h>
#include <pthread.h>
#pragma comment(lib,"ws2_32.lib")
#pragma comment(lib, "pthreadVC2.lib")

	count=1;
	sockfd[1000]={0};
	sockaddr_len=0;
	WSADATA wsaData;	/* windows socket stuff */
	
	struct sockaddr_in client_addr;	/* socket stuff */
	struct sockaddr_in serv_addr;
	pthread_mutex_t lock;	

sf0()	/* #4 add */
{

	int retn_select=0,retn_recv=0;
	fd_set fdset0;  /* select() stuff */
	struct timeval timeout;	/* select() stuff */
	char* recv_buff0=NULL;
	int sub_count=0,sec_count=0;
pthread_mutex_lock(&lock);
	sub_count=count;
	recv_buff0=(char *)malloc(10000);
	
	sockfd[sub_count]=accept(sockfd[0],(struct sockaddr*)&client_addr,&sockaddr_len);
	++count;
pthread_mutex_unlock(&lock);
	Sleep(1000);
	printf("sockfd[%d] is connected !??/n",sub_count);
	send(sockfd[sub_count],"You're connected to Server??/n",27,0);	/* printf("%d??/n",count); */

	for (;;) {
		FD_ZERO(&fdset0);
		FD_SET(sockfd[sub_count],&fdset0);	/* set monitor fd for select() */
		timeout.tv_sec=1;
		timeout.tv_usec=0;	/* set timeout of select() */
		
		retn_select=select(sockfd[sub_count]+1,&fdset0,NULL,NULL,&timeout);
		if (retn_select<0) {perror("select");break;}
		
		if (FD_ISSET(sockfd[sub_count],&fdset0)) {
			memset(recv_buff0,0,10000);
			retn_recv=recv(sockfd[sub_count],recv_buff0,10000,0);
			if (retn_recv==-1) {printf("sockfd[%d] disconnect...??/n",sub_count);break;}
			printf("%s??/n",recv_buff0);
			
			for (sec_count=count;sec_count>0;--sec_count) {
				if (sec_count != sub_count) send(sockfd[sec_count],recv_buff0,retn_recv,0);
			}
		}
	}	
}

sf1()
{

	int retn_select=0,retn_recv=0;
	fd_set fdset0;  /* select() stuff */
	struct timeval timeout;	/* select() stuff */
	char* recv_buff0=NULL;
	int sub_count=0,sec_count=0;
pthread_mutex_lock(&lock);
	sub_count=count;
	recv_buff0=(char *)malloc(10000);
	
	sockfd[sub_count]=accept(sockfd[0],(struct sockaddr*)&client_addr,&sockaddr_len);
	++count;
pthread_mutex_unlock(&lock);
	Sleep(1000);
	printf("sockfd[%d] is connected !??/n",sub_count);
	send(sockfd[sub_count],"You're connected to Server??/n",27,0);	/* printf("%d??/n",count); */

	for (;;) {
		FD_ZERO(&fdset0);
		FD_SET(sockfd[sub_count],&fdset0);	/* set monitor fd for select() */
		timeout.tv_sec=1;
		timeout.tv_usec=0;	/* set timeout of select() */
		
		retn_select=select(sockfd[sub_count]+1,&fdset0,NULL,NULL,&timeout);
		if (retn_select<0) {perror("select");break;}
		
		if (FD_ISSET(sockfd[sub_count],&fdset0)) {
			memset(recv_buff0,0,10000);
			retn_recv=recv(sockfd[sub_count],recv_buff0,10000,0);
			if (retn_recv==-1) {printf("sockfd[%d] disconnect...??/n",sub_count);break;}
			printf("%s??/n",recv_buff0);
			
			for (sec_count=count;sec_count>0;--sec_count) {
				if (sec_count != sub_count) send(sockfd[sec_count],recv_buff0,retn_recv,0);
			}
		}
	}	
}

sf2()
{

	int retn_select=0,retn_recv=0;
	fd_set fdset0;  /* select() stuff */
	struct timeval timeout;	/* select() stuff */
	char* recv_buff0=NULL;
	int sub_count=0,sec_count=0;
pthread_mutex_lock(&lock);
	sub_count=count;
	recv_buff0=(char *)malloc(10000);
	
	sockfd[sub_count]=accept(sockfd[0],(struct sockaddr*)&client_addr,&sockaddr_len);
	++count;
pthread_mutex_unlock(&lock);
	Sleep(1000);
	printf("sockfd[%d] is connected !??/n",sub_count);
	send(sockfd[sub_count],"You're connected to Server??/n",27,0);	/* printf("%d??/n",count); */

	for (;;) {
		FD_ZERO(&fdset0);
		FD_SET(sockfd[sub_count],&fdset0);	/* set monitor fd for select() */
		timeout.tv_sec=1;
		timeout.tv_usec=0;	/* set timeout of select() */
		
		retn_select=select(sockfd[sub_count]+1,&fdset0,NULL,NULL,&timeout);
		if (retn_select<0) {perror("select");break;}
		
		if (FD_ISSET(sockfd[sub_count],&fdset0)) {
			memset(recv_buff0,0,10000);
			retn_recv=recv(sockfd[sub_count],recv_buff0,10000,0);
			if (retn_recv==-1) {printf("sockfd[%d] disconnect...??/n",sub_count);break;}
			printf("%s??/n",recv_buff0);
			
			for (sec_count=count;sec_count>0;--sec_count) {
				if (sec_count != sub_count) send(sockfd[sec_count],recv_buff0,retn_recv,0);
			}
		}
	}	
}

sf3()
{

	int retn_select=0,retn_recv=0;
	fd_set fdset0;  /* select() stuff */
	struct timeval timeout;	/* select() stuff */
	char* recv_buff0=NULL;
	int sub_count=0,sec_count=0;
pthread_mutex_lock(&lock);
	sub_count=count;
	recv_buff0=(char *)malloc(10000);
	
	sockfd[sub_count]=accept(sockfd[0],(struct sockaddr*)&client_addr,&sockaddr_len);
	++count;
pthread_mutex_unlock(&lock);
	Sleep(1000);
	printf("sockfd[%d] is connected !??/n",sub_count);
	send(sockfd[sub_count],"You're connected to Server??/n",27,0);	/* printf("%d??/n",count); */

	for (;;) {
		FD_ZERO(&fdset0);
		FD_SET(sockfd[sub_count],&fdset0);	/* set monitor fd for select() */
		timeout.tv_sec=1;
		timeout.tv_usec=0;	/* set timeout of select() */
		
		retn_select=select(sockfd[sub_count]+1,&fdset0,NULL,NULL,&timeout);
		if (retn_select<0) {perror("select");break;}
		
		if (FD_ISSET(sockfd[sub_count],&fdset0)) {
			memset(recv_buff0,0,10000);
			retn_recv=recv(sockfd[sub_count],recv_buff0,10000,0);
			if (retn_recv==-1) {printf("sockfd[%d] disconnect...??/n",sub_count);break;}
			printf("%s??/n",recv_buff0);
			
			for (sec_count=count;sec_count>0;--sec_count) {
				if (sec_count != sub_count) send(sockfd[sec_count],recv_buff0,retn_recv,0);
			}
		}
	}	
}

sf4()
{

	int retn_select=0,retn_recv=0;
	fd_set fdset0;  /* select() stuff */
	struct timeval timeout;	/* select() stuff */
	char* recv_buff0=NULL;
	int sub_count=0,sec_count=0;
pthread_mutex_lock(&lock);
	sub_count=count;
	recv_buff0=(char *)malloc(10000);
	
	sockfd[sub_count]=accept(sockfd[0],(struct sockaddr*)&client_addr,&sockaddr_len);
	++count;
pthread_mutex_unlock(&lock);
	Sleep(1000);
	printf("sockfd[%d] is connected !??/n",sub_count);
	send(sockfd[sub_count],"You're connected to Server??/n",27,0);	/* printf("%d??/n",count); */

	for (;;) {
		FD_ZERO(&fdset0);
		FD_SET(sockfd[sub_count],&fdset0);	/* set monitor fd for select() */
		timeout.tv_sec=1;
		timeout.tv_usec=0;	/* set timeout of select() */
		
		retn_select=select(sockfd[sub_count]+1,&fdset0,NULL,NULL,&timeout);
		if (retn_select<0) {perror("select");break;}
		
		if (FD_ISSET(sockfd[sub_count],&fdset0)) {
			memset(recv_buff0,0,10000);
			retn_recv=recv(sockfd[sub_count],recv_buff0,10000,0);
			if (retn_recv==-1) {printf("sockfd[%d] disconnect...??/n",sub_count);break;}
			printf("%s??/n",recv_buff0);
			
			for (sec_count=count;sec_count>0;--sec_count) {
				if (sec_count != sub_count) send(sockfd[sec_count],recv_buff0,retn_recv,0);
			}
		}
	}	
}

sf5()
{

	int retn_select=0,retn_recv=0;
	fd_set fdset0;  /* select() stuff */
	struct timeval timeout;	/* select() stuff */
	char* recv_buff0=NULL;
	int sub_count=0,sec_count=0;
pthread_mutex_lock(&lock);
	sub_count=count;
	recv_buff0=(char *)malloc(10000);
	
	sockfd[sub_count]=accept(sockfd[0],(struct sockaddr*)&client_addr,&sockaddr_len);
	++count;
pthread_mutex_unlock(&lock);
	Sleep(1000);
	printf("sockfd[%d] is connected !??/n",sub_count);
	send(sockfd[sub_count],"You're connected to Server??/n",27,0);	/* printf("%d??/n",count); */

	for (;;) {
		FD_ZERO(&fdset0);
		FD_SET(sockfd[sub_count],&fdset0);	/* set monitor fd for select() */
		timeout.tv_sec=1;
		timeout.tv_usec=0;	/* set timeout of select() */
		
		retn_select=select(sockfd[sub_count]+1,&fdset0,NULL,NULL,&timeout);
		if (retn_select<0) {perror("select");break;}
		
		if (FD_ISSET(sockfd[sub_count],&fdset0)) {
			memset(recv_buff0,0,10000);
			retn_recv=recv(sockfd[sub_count],recv_buff0,10000,0);
			if (retn_recv==-1) {printf("sockfd[%d] disconnect...??/n",sub_count);break;}
			printf("%s??/n",recv_buff0);
			
			for (sec_count=count;sec_count>0;--sec_count) {
				if (sec_count != sub_count) send(sockfd[sec_count],recv_buff0,retn_recv,0);
			}
		}
	}	
}

sf6()
{

	int retn_select=0,retn_recv=0;
	fd_set fdset0;  /* select() stuff */
	struct timeval timeout;	/* select() stuff */
	char* recv_buff0=NULL;
	int sub_count=0,sec_count=0;
pthread_mutex_lock(&lock);
	sub_count=count;
	recv_buff0=(char *)malloc(10000);
	
	sockfd[sub_count]=accept(sockfd[0],(struct sockaddr*)&client_addr,&sockaddr_len);
	++count;
pthread_mutex_unlock(&lock);
	Sleep(1000);
	printf("sockfd[%d] is connected !??/n",sub_count);
	send(sockfd[sub_count],"You're connected to Server??/n",27,0);	/* printf("%d??/n",count); */

	for (;;) {
		FD_ZERO(&fdset0);
		FD_SET(sockfd[sub_count],&fdset0);	/* set monitor fd for select() */
		timeout.tv_sec=1;
		timeout.tv_usec=0;	/* set timeout of select() */
		
		retn_select=select(sockfd[sub_count]+1,&fdset0,NULL,NULL,&timeout);
		if (retn_select<0) {perror("select");break;}
		
		if (FD_ISSET(sockfd[sub_count],&fdset0)) {
			memset(recv_buff0,0,10000);
			retn_recv=recv(sockfd[sub_count],recv_buff0,10000,0);
			if (retn_recv==-1) {printf("sockfd[%d] disconnect...??/n",sub_count);break;}
			printf("%s??/n",recv_buff0);
			
			for (sec_count=count;sec_count>0;--sec_count) {
				if (sec_count != sub_count) send(sockfd[sec_count],recv_buff0,retn_recv,0);
			}
		}
	}	
}

sf7()
{

	int retn_select=0,retn_recv=0;
	fd_set fdset0;  /* select() stuff */
	struct timeval timeout;	/* select() stuff */
	char* recv_buff0=NULL;
	int sub_count=0,sec_count=0;
pthread_mutex_lock(&lock);
	sub_count=count;
	recv_buff0=(char *)malloc(10000);
	
	sockfd[sub_count]=accept(sockfd[0],(struct sockaddr*)&client_addr,&sockaddr_len);
	++count;
pthread_mutex_unlock(&lock);
	Sleep(1000);
	printf("sockfd[%d] is connected !??/n",sub_count);
	send(sockfd[sub_count],"You're connected to Server??/n",27,0);	/* printf("%d??/n",count); */

	for (;;) {
		FD_ZERO(&fdset0);
		FD_SET(sockfd[sub_count],&fdset0);	/* set monitor fd for select() */
		timeout.tv_sec=1;
		timeout.tv_usec=0;	/* set timeout of select() */
		
		retn_select=select(sockfd[sub_count]+1,&fdset0,NULL,NULL,&timeout);
		if (retn_select<0) {perror("select");break;}
		
		if (FD_ISSET(sockfd[sub_count],&fdset0)) {
			memset(recv_buff0,0,10000);
			retn_recv=recv(sockfd[sub_count],recv_buff0,10000,0);
			if (retn_recv==-1) {printf("sockfd[%d] disconnect...??/n",sub_count);break;}
			printf("%s??/n",recv_buff0);
			
			for (sec_count=count;sec_count>0;--sec_count) {
				if (sec_count != sub_count) send(sockfd[sec_count],recv_buff0,retn_recv,0);
			}
		}
	}	
}

sf8()
{

	int retn_select=0,retn_recv=0;
	fd_set fdset0;  /* select() stuff */
	struct timeval timeout;	/* select() stuff */
	char* recv_buff0=NULL;
	int sub_count=0,sec_count=0;
pthread_mutex_lock(&lock);
	sub_count=count;
	recv_buff0=(char *)malloc(10000);
	
	sockfd[sub_count]=accept(sockfd[0],(struct sockaddr*)&client_addr,&sockaddr_len);
	++count;
pthread_mutex_unlock(&lock);
	Sleep(1000);
	printf("sockfd[%d] is connected !??/n",sub_count);
	send(sockfd[sub_count],"You're connected to Server??/n",27,0);	/* printf("%d??/n",count); */

	for (;;) {
		FD_ZERO(&fdset0);
		FD_SET(sockfd[sub_count],&fdset0);	/* set monitor fd for select() */
		timeout.tv_sec=1;
		timeout.tv_usec=0;	/* set timeout of select() */
		
		retn_select=select(sockfd[sub_count]+1,&fdset0,NULL,NULL,&timeout);
		if (retn_select<0) {perror("select");break;}
		
		if (FD_ISSET(sockfd[sub_count],&fdset0)) {
			memset(recv_buff0,0,10000);
			retn_recv=recv(sockfd[sub_count],recv_buff0,10000,0);
			if (retn_recv==-1) {printf("sockfd[%d] disconnect...??/n",sub_count);break;}
			printf("%s??/n",recv_buff0);
			
			for (sec_count=count;sec_count>0;--sec_count) {
				if (sec_count != sub_count) send(sockfd[sec_count],recv_buff0,retn_recv,0);
			}
		}
	}	
}

sf9()
{

	int retn_select=0,retn_recv=0;
	fd_set fdset0;  /* select() stuff */
	struct timeval timeout;	/* select() stuff */
	char* recv_buff0=NULL;
	int sub_count=0,sec_count=0;
pthread_mutex_lock(&lock);
	sub_count=count;
	recv_buff0=(char *)malloc(10000);
	
	sockfd[sub_count]=accept(sockfd[0],(struct sockaddr*)&client_addr,&sockaddr_len);
	++count;
pthread_mutex_unlock(&lock);
	Sleep(1000);
	printf("sockfd[%d] is connected !??/n",sub_count);
	send(sockfd[sub_count],"You're connected to Server??/n",27,0);	/* printf("%d??/n",count); */

	for (;;) {
		FD_ZERO(&fdset0);
		FD_SET(sockfd[sub_count],&fdset0);	/* set monitor fd for select() */
		timeout.tv_sec=1;
		timeout.tv_usec=0;	/* set timeout of select() */
		
		retn_select=select(sockfd[sub_count]+1,&fdset0,NULL,NULL,&timeout);
		if (retn_select<0) {perror("select");break;}
		
		if (FD_ISSET(sockfd[sub_count],&fdset0)) {
			memset(recv_buff0,0,10000);
			retn_recv=recv(sockfd[sub_count],recv_buff0,10000,0);
			if (retn_recv==-1) {printf("sockfd[%d] disconnect...??/n",sub_count);break;}
			printf("%s??/n",recv_buff0);
			
			for (sec_count=count;sec_count>0;--sec_count) {
				if (sec_count != sub_count) send(sockfd[sec_count],recv_buff0,retn_recv,0);
			}
		}
	}	
}

sf10()
{

	int retn_select=0,retn_recv=0;
	fd_set fdset0;  /* select() stuff */
	struct timeval timeout;	/* select() stuff */
	char* recv_buff0=NULL;
	int sub_count=0,sec_count=0;
pthread_mutex_lock(&lock);
	sub_count=count;
	recv_buff0=(char *)malloc(10000);
	
	sockfd[sub_count]=accept(sockfd[0],(struct sockaddr*)&client_addr,&sockaddr_len);
	++count;
pthread_mutex_unlock(&lock);
	Sleep(1000);
	printf("sockfd[%d] is connected !??/n",sub_count);
	send(sockfd[sub_count],"You're connected to Server??/n",27,0);	/* printf("%d??/n",count); */

	for (;;) {
		FD_ZERO(&fdset0);
		FD_SET(sockfd[sub_count],&fdset0);	/* set monitor fd for select() */
		timeout.tv_sec=1;
		timeout.tv_usec=0;	/* set timeout of select() */
		
		retn_select=select(sockfd[sub_count]+1,&fdset0,NULL,NULL,&timeout);
		if (retn_select<0) {perror("select");break;}
		
		if (FD_ISSET(sockfd[sub_count],&fdset0)) {
			memset(recv_buff0,0,10000);
			retn_recv=recv(sockfd[sub_count],recv_buff0,10000,0);
			if (retn_recv==-1) {printf("sockfd[%d] disconnect...??/n",sub_count);break;}
			printf("%s??/n",recv_buff0);
			
			for (sec_count=count;sec_count>0;--sec_count) {
				if (sec_count != sub_count) send(sockfd[sec_count],recv_buff0,retn_recv,0);
			}
		}
	}	
}

sf11()
{

	int retn_select=0,retn_recv=0;
	fd_set fdset0;  /* select() stuff */
	struct timeval timeout;	/* select() stuff */
	char* recv_buff0=NULL;
	int sub_count=0,sec_count=0;
pthread_mutex_lock(&lock);
	sub_count=count;
	recv_buff0=(char *)malloc(10000);
	
	sockfd[sub_count]=accept(sockfd[0],(struct sockaddr*)&client_addr,&sockaddr_len);
	++count;
pthread_mutex_unlock(&lock);
	Sleep(1000);
	printf("sockfd[%d] is connected !??/n",sub_count);
	send(sockfd[sub_count],"You're connected to Server??/n",27,0);	/* printf("%d??/n",count); */

	for (;;) {
		FD_ZERO(&fdset0);
		FD_SET(sockfd[sub_count],&fdset0);	/* set monitor fd for select() */
		timeout.tv_sec=1;
		timeout.tv_usec=0;	/* set timeout of select() */
		
		retn_select=select(sockfd[sub_count]+1,&fdset0,NULL,NULL,&timeout);
		if (retn_select<0) {perror("select");break;}
		
		if (FD_ISSET(sockfd[sub_count],&fdset0)) {
			memset(recv_buff0,0,10000);
			retn_recv=recv(sockfd[sub_count],recv_buff0,10000,0);
			if (retn_recv==-1) {printf("sockfd[%d] disconnect...??/n",sub_count);break;}
			printf("%s??/n",recv_buff0);
			
			for (sec_count=count;sec_count>0;--sec_count) {
				if (sec_count != sub_count) send(sockfd[sec_count],recv_buff0,retn_recv,0);
			}
		}
	}	
}

/* ... */
	
main()
{

/* if it needs more clients to connected, add 4 area ,then right */

	pthread_t pid0,pid1,pid2,pid3,pid4,pid5,pid6,pid7,pid8,pid9,pid10,pid11;	/* #1 add */

	WSAStartup(MAKEWORD(2,2),&wsaData);	/* windows socket init ... */
	sockaddr_len=sizeof(struct sockaddr);
	serv_addr.sin_family=AF_INET;
	serv_addr.sin_addr.s_addr=htonl(INADDR_ANY);
	serv_addr.sin_port=htons(60502);
	sockfd[0]=socket(AF_INET,SOCK_STREAM,IPPROTO_TCP);

	system("color 30");	/* call DOS API */
	system("title Server");
	system("cls");
	printf("Welcome to server??/n");

	
	bind(sockfd[0],(struct sockaddr*)&serv_addr,sockaddr_len);
	listen(sockfd[0],10);

	pthread_mutex_init(&lock,NULL);

	pthread_create(&pid0,NULL,(void *)&sf0,NULL);	/* #2 add */
	pthread_create(&pid1,NULL,(void *)&sf1,NULL);
	pthread_create(&pid2,NULL,(void *)&sf2,NULL);
	pthread_create(&pid3,NULL,(void *)&sf3,NULL);
	pthread_create(&pid4,NULL,(void *)&sf4,NULL);
	pthread_create(&pid5,NULL,(void *)&sf5,NULL);
	pthread_create(&pid6,NULL,(void *)&sf6,NULL);
	pthread_create(&pid7,NULL,(void *)&sf7,NULL);
	pthread_create(&pid8,NULL,(void *)&sf8,NULL);
	pthread_create(&pid9,NULL,(void *)&sf9,NULL);
	pthread_create(&pid10,NULL,(void *)&sf10,NULL);
	pthread_create(&pid11,NULL,(void *)&sf11,NULL);

	pthread_join(pid0,NULL);	/* #3 add */
	pthread_join(pid1,NULL);
	pthread_join(pid2,NULL);
	pthread_join(pid3,NULL);
	pthread_join(pid4,NULL);
	pthread_join(pid5,NULL);
	pthread_join(pid6,NULL);
	pthread_join(pid7,NULL);
	pthread_join(pid8,NULL);
	pthread_join(pid9,NULL);
	pthread_join(pid10,NULL);
	pthread_join(pid11,NULL);

	closesocket(sockfd[0]);
	WSACleanup();
	getch();	/* wait for a key to input, like pause */
	return 0;
}
	


	
	
	
