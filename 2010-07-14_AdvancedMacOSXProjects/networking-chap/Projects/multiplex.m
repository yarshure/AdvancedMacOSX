//gcc -g -std=c99 -Wall -DUSE_POLL -o poll multiplex.m
//gcc -g -std=c99 -Wall -DUSE_SELECT -o select multiplex.m
// A server that accepts connections and echoes whatever is written.
// Multiplexes the connections using poll or select.

#import <stdlib.h>
#import <stdio.h>
#import <stdbool.h>
#import <string.h>
#import <time.h>

#import <arpa/inet.h>
#import <errno.h>
#import <fcntl.h>
#import <netinet/in.h>
#import <netinet6/in6.h>
#import <poll.h>
#import <sys/select.h>
#import <sys/queue.h>
#import <sys/socket.h>
#import <unistd.h>

#define MAX(x, y) (((x) > (y))? (x) : (y))
#define MIN(x, y) (((x) < (y))? (x) : (y))

const in_port_t kPortNumber = 0;
const int kBacklogHint = 20;
const char kExitCommand[] = "*** EXIT ***";

int GetListeningSocket(sa_family_t proto);
void RunServer(int listenfd);

int
main(int argc, char *argv[]) {
	const sa_family_t proto = (argc > 1)? PF_INET6 : PF_INET;
	int sockfd = GetListeningSocket(proto);
	if (-1 == sockfd) return EXIT_FAILURE;

	RunServer(sockfd);
	close(sockfd);
	return EXIT_SUCCESS;
}

int
GetListeningSocket(sa_family_t proto) {
	in_port_t *port_p = NULL;
	void *addr_p = NULL;
	union {
		struct sockaddr sa;
		struct sockaddr_in in;
		struct sockaddr_in6 in6;
	} addr;
	if (PF_INET == proto) {
		addr.in.sin_len = sizeof(addr.in);
		addr.in.sin_family = proto;
		addr.in.sin_port = htons(kPortNumber);
		addr.in.sin_addr.s_addr = htonl(INADDR_ANY);
		(void)memset(&addr.in.sin_zero, 0, sizeof(addr.in.sin_zero));
		port_p = &addr.in.sin_port;
		addr_p = &addr.in.sin_addr;
	} else if (PF_INET6 == proto) {
		addr.in6.sin6_len = sizeof(addr.in6);
		addr.in6.sin6_family = proto;
		addr.in6.sin6_port = htons(kPortNumber);
		addr.in6.sin6_flowinfo = 0;
		addr.in6.sin6_addr = in6addr_any;
		addr.in6.sin6_scope_id = 0;
		port_p = &addr.in6.sin6_port;
		addr_p = &addr.in6.sin6_addr;
	} else {
		fprintf(stderr, "%s: *** Unknown proto: %d\n", __func__, (int)proto);
		return -1;
	}

	int sockfd = socket(proto, SOCK_STREAM, 0);
	if (-1 == sockfd) {
		perror("socket");
		return sockfd;
	}

	const int should_reuse = true;
	int err = setsockopt(sockfd, SOL_SOCKET, SO_REUSEADDR,
	                     &should_reuse, sizeof(should_reuse));
	if (-1 == err) perror("setsockopt(SO_REUSEADDR=true)");

	err = bind(sockfd, &addr.sa, addr.sa.sa_len);
	if (-1 == err) {
		perror("bind");
		close(sockfd), sockfd = -1;
		return sockfd;
	}

	err = listen(sockfd, kBacklogHint);
	if (-1 == err) {
		perror("listen");
		close(sockfd), sockfd = -1;
	} else {
		socklen_t len = addr.sa.sa_len;
		err = getsockname(sockfd, &addr.sa, &len);
		if (-1 == err) perror("getsockname");

		char pres[INET6_ADDRSTRLEN];
		const char *name = inet_ntop(addr.sa.sa_family, addr_p,
		                             pres, sizeof(pres));
		if (NULL == name) {
			perror("inet_ntop");
			printf("[Listening on port %d.]\n", (int)ntohs(*port_p));
		} else {
			fprintf(stderr, "[Listening on %s port %d.]\n",
			        name, (int)ntohs(*port_p));
		}
	}
	return sockfd;
}

struct client {
	int fd;
	bool ready_read;
	SLIST_ENTRY(client) next;
};
SLIST_HEAD(clienthead, client) clients = SLIST_HEAD_INITIALIZER(clients);

struct client_data {
	struct clienthead *clients;
	size_t client_count;
} client_data = { &clients, 0 };

#if USE_POLL
struct multi_data {
	char *buffer;
	size_t buffer_len;
	struct pollfd *pollfd;
	size_t pollfd_count;
} multi_data = { NULL, 0 };
#elif USE_SELECT
struct multi_data {
	char *buffer;
	size_t buffer_len;
	fd_set fdset;
	int fdset_count;
} multi_data = { 0, 0 };
#else
#error Must define USE_POLL or USE_SELECT.
#endif

bool MultiInit(struct multi_data *);
void MultiUpdateForClients(struct multi_data *, struct client_data *);
int Multiplex(struct multi_data *);
bool MultiUpdateClientsWithResult(int, struct multi_data *, struct client_data *);
bool MultiFinalize(struct multi_data *);

void
RunServer(int listenfd) {
	if (-1 == listenfd) {
		fprintf(stderr, "%s: *** Bad listenfd.\n", __func__);
		return;
	}
	
	SLIST_INIT(&clients);
	// Add the first "client" - the listenfd.
	struct client *const listen_client = malloc(sizeof(*listen_client));
	listen_client->fd = listenfd;
	listen_client->ready_read = false;
	SLIST_INSERT_HEAD(&clients, listen_client, next);
	client_data.client_count += 1;
	
	if (!MultiInit(&multi_data)) return;

	const size_t exit_cmd_len = strlen(kExitCommand);
	fprintf(stderr, "[Terminate command is: %s]\n", kExitCommand);
	bool should_exit = false;

	while (!should_exit) {
		MultiUpdateForClients(&multi_data, &client_data);
		int err = Multiplex(&multi_data);
		bool okay = MultiUpdateClientsWithResult(err, &multi_data, &client_data);
		if (!okay) break;

		struct client *client, *client_safe;
		SLIST_FOREACH_SAFE(client, &clients, next, client_safe) {
			if (!client->ready_read) continue;
			client->ready_read = false;

			if (listen_client == client) {
				fprintf(stderr, "New client connection...\n");
				struct sockaddr_storage addr;
				socklen_t addr_len = sizeof(addr);
				const int new_fd = accept(client->fd,
												  (struct sockaddr *)&addr, &addr_len);
				if (-1 == new_fd) {
					perror("accept");
					continue;
				}
				fprintf(stderr, "Connection opened: fd %d\n", new_fd);

				int err = fcntl(new_fd, F_SETFL, O_NONBLOCK);
				if (-1 == err) {
					perror("fcntl(client O_NONBLOCK)");
				}

				struct client *const c = malloc(sizeof(*c));
				if (NULL == c) {
					perror("malloc(client)");
					close(new_fd);
					continue;
				}

				c->fd = new_fd;
				c->ready_read = false;

				SLIST_INSERT_HEAD(&clients, c, next);
				client_data.client_count += 1;
				fprintf(stderr, "Added new client (%zu total)\n",
				        client_data.client_count);
			} else {
				ssize_t nread = read(client->fd, multi_data.buffer, multi_data.buffer_len);
				if (-1 == nread) {
					perror("read(client->fd)");
					continue;
				}

				if (0 == nread) {
					fprintf(stderr, "Connection closed: fd %d\n", client->fd);
					close(client->fd);
					
					SLIST_REMOVE(&clients, client, client, next);
					client_data.client_count -= 1;
					fprintf(stderr, "Removed client (%zu remaining)\n",
					        client_data.client_count);
					continue;
				}

				printf("%d: %.*s", client->fd, (int)nread, multi_data.buffer);
				if (exit_cmd_len <= nread
				    && memcmp(multi_data.buffer, kExitCommand, exit_cmd_len) == 0)
					should_exit = true;
			}
		}
	}

	MultiFinalize(&multi_data);

	// clean up the list
	const char exiting_msg[] = "[Server exiting.]\n";
	const size_t exiting_msg_len = strlen(exiting_msg);
	for (struct client *client; !SLIST_EMPTY(&clients);) {
		client = SLIST_FIRST(&clients);
		(void)write(client->fd, exiting_msg, exiting_msg_len);
		close(client->fd);
		SLIST_REMOVE_HEAD(&clients, next);
		free(client);
	}

	fprintf(stderr, "%s", exiting_msg);
}

#if USE_POLL
bool
MultiInit(struct multi_data *mdat) {
	if (NULL == mdat) {
		fprintf(stderr, "%s: *** Null mdat.\n", __func__);
		return false;
	}

	// Get a buffer to read into.
	mdat->buffer_len = getpagesize();
	if (-1 == mdat->buffer_len) {
		perror("getpagesize");
		mdat->buffer_len = 4096;
	}

	mdat->buffer = malloc(mdat->buffer_len);
	if (NULL == mdat->buffer) {
		perror("malloc");
		return false;
	}

	mdat->pollfd_count = 10;
	mdat->pollfd = calloc(mdat->pollfd_count, sizeof(*mdat->pollfd));
	if (NULL == mdat->pollfd) {
		perror("calloc");
		return false;
	}
	return true;
}

void
MultiUpdateForClients(struct multi_data *mdat, struct client_data *cdat) {
	if (cdat->client_count > mdat->pollfd_count) {
		fprintf(stderr, "%s: doubling pollfd array size\n", __func__);
		size_t new_count = 2 * mdat->pollfd_count;
		void *new_ptr = realloc(mdat->pollfd, new_count * sizeof(*mdat->pollfd));
		if (NULL == new_ptr) perror("realloc");
		else {
			mdat->pollfd = new_ptr;
			mdat->pollfd_count = new_count;
		}
	}

	const size_t min_count = MIN(mdat->pollfd_count, cdat->client_count);
	int i = 0;
	struct client *c = NULL;
	SLIST_FOREACH(c, cdat->clients, next) {
		struct pollfd *p = &mdat->pollfd[i];
		p->fd = c->fd;
		p->events |= POLLIN;
		p->revents = 0;

		i += 1;
		if (i >= min_count) break;
	}
}

int
Multiplex(struct multi_data *mdat) {
	const time_t now = time(NULL);

	int timeoutMs = 15000;  // -1 to never timeout
	fprintf(stderr, "%s: polling with timeout of %d ms\n", __func__, timeoutMs);
	int err = poll(mdat->pollfd, mdat->pollfd_count, timeoutMs);

	const time_t then = time(NULL);
	double elapsed = difftime(then, now);
	fprintf(stderr, "%s: poll waited %g seconds\n", __func__, elapsed);
	return err;
}

bool
MultiUpdateClientsWithResult(int res, struct multi_data *mdat, struct client_data *cdat) {
	if (-1 == res) {
		const bool okay = (EINTR == errno);
		perror("poll");
		return okay;
	}

	fprintf(stderr, "[%d fds ready]\n", res);
	if (0 == res) return true;

	const size_t min_count = MIN(mdat->pollfd_count, cdat->client_count);
	int i = 0;
	struct client *c = NULL;
	SLIST_FOREACH(c, cdat->clients, next) {
		struct pollfd *p = &mdat->pollfd[i];
		c->ready_read = (p->revents & POLLIN);

		i += 1;
		if (i >= min_count) break;
	}
	return true;
}

bool
MultiFinalize(struct multi_data *mdat) {
	if (NULL == mdat) return false;

	if (NULL != mdat->pollfd) free(mdat->pollfd);
	mdat->pollfd_count = 0;
	if (NULL != mdat->buffer) free(mdat->buffer);
	mdat->buffer_len = 0;
	return true;
}
#elif USE_SELECT
bool
MultiInit(struct multi_data *mdat) {
	if (NULL == mdat) {
		fprintf(stderr, "%s: *** Null mdat.\n", __func__);
		return false;
	}

	// Get a buffer to read into.
	mdat->buffer_len = getpagesize();
	if (-1 == mdat->buffer_len) {
		perror("getpagesize");
		mdat->buffer_len = 4096;
	}

	mdat->buffer = malloc(mdat->buffer_len);
	if (NULL == mdat->buffer) {
		perror("malloc");
		return false;
	}
	return true;
}

void
MultiUpdateForClients(struct multi_data *mdat, struct client_data *cdat) {
	FD_ZERO(&mdat->fdset);
	mdat->fdset_count = 0;

	struct client *c = NULL;
	SLIST_FOREACH(c, cdat->clients, next) {
		if (c->fd < FD_SETSIZE) {
			FD_SET(c->fd, &mdat->fdset);
			mdat->fdset_count = MAX(c->fd, mdat->fdset_count);
		} else {
			fprintf(stderr, "*** fd too big: %d (>= %d)\n",
			        c->fd, (int)FD_SETSIZE);
		}
	}

	mdat->fdset_count += 1;
}

int
Multiplex(struct multi_data *mdat) {
	int nfds = select(mdat->fdset_count, &mdat->fdset, NULL, NULL, NULL);
	return nfds;
}

bool
MultiUpdateClientsWithResult(int res, struct multi_data *mdat, struct client_data *cdat) {
	if (-1 == res) {
		perror("select");
		return false;
	}

	fprintf(stderr, "[%d fds ready]\n", res);
	if (0 == res) return true;

	struct client *c;
	SLIST_FOREACH(c, cdat->clients, next) {
		c->ready_read = FD_ISSET(c->fd, &mdat->fdset);
	}
	return true;
}

bool
MultiFinalize(struct multi_data *mdat) {
	if (NULL == mdat) return false;
	if (NULL != mdat->buffer) free(mdat->buffer);
	mdat->buffer_len = 0;
	return true;
}
#endif

// vi:set noet ts=3 sw=3:
