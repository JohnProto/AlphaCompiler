CC = gcc
EXEC = scanner
SOURCE = al.l
FLEX_OUTPUT = lex.yy.c

all: $(EXEC)

$(EXEC): $(FLEX_OUTPUT)
	$(CC) -o $(EXEC) $(FLEX_OUTPUT)

$(FLEX_OUTPUT): $(SOURCE)
	flex $(SOURCE)

clean:
	rm $(FLEX_OUTPUT) $(EXEC)