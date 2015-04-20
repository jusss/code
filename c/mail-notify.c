#include <stdio.h>

#include <stdlib.h>

#include <malloc.h>

#include <string.h>

#include <netinet/in.h>

#include <sys/types.h>

#include <sys/socket.h>

#include <unistd.h>

#include <sys/stat.h>
#include <fcntl.h>


int main()

{

	char *nick = "NICK mail-bot9a\r\n";

	char *user = "USER mailbot 8 * :mailbot\r\n";

	char *channel = "join #irc-ctrl-shell\r\n";

	char *notification = "privmsg #irc-ctrl-shell :jusss: you have a new mail!\r\n";
	char recv_irc_msg[1000] = {0};



	int sockfd[1000] = {0};



	struct sockaddr_in irc_addr;



	irc_addr.sin_family = AF_INET;

	irc_addr.sin_addr.s_addr = inet_addr("64.32.24.176");
	irc_addr.sin_port = htons(6665);



	sockfd[0] = socket(AF_INET,SOCK_STREAM,IPPROTO_TCP);



	connect(sockfd[0],(struct sockaddr*)&irc_addr,sizeof(irc_addr));



	send(sockfd[0],nick,strlen(nick),0);

	send(sockfd[0],user,strlen(user),0);



	/* test if it has received all message of the server */

	while ( 1 ) {

		memset(recv_irc_msg,0,1000);

		recv(sockfd[0],recv_irc_msg,1000,0);

		printf("%s",recv_irc_msg); /* delete me */

		if (strstr(recv_irc_msg,":End of /MOTD command.")) break;

	}

	

	send(sockfd[0],channel,strlen(channel),0);



	/* test if it has joined the channel */

	while ( 1 ) {

		memset(recv_irc_msg,0,1000);

		recv(sockfd[0],recv_irc_msg,1000,0);

		printf("%s",recv_irc_msg); /* delete me */

		if (strstr(recv_irc_msg,"#irc-ctrl-shell :End of /NAMES list.")) {

			printf("already joined the channel\r\n");

			break;

		}

	}



	send(sockfd[0],notification,strlen(notification),0);
	send(sockfd[0],"quit\r\n",6,0);
	close(sockfd[0]);
	return 0;

}



