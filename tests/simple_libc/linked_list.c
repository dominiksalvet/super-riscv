/*
    Super RISC-V - superscalar dual-issue RISC-V processor
    Copyright (C) 2025 Dominik Salvet

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <https://www.gnu.org/licenses/>.
*/

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define LINE_MAX_L 128
#define MSG "link. links make to list linked this linked Linker"

// double linked list
struct node_t {
    char *text;
    struct node_t *prev;
    struct node_t *next;
};

int main(int argc, char const *argv[])
{
    char line[LINE_MAX_L];

    if (!fgets(line, sizeof line, stdin)) {
        return 1;
    }
    // remove newline character
    int line_len = strlen(line);
    if (line[line_len - 1] == '\n') {
        line[line_len - 1] = '\0';
    }

    // initialize token parsing
    char *word = strtok(line, " ");
    if (!word) {
        return 2;
    }

    struct node_t *head = malloc(sizeof(struct node_t));
    struct node_t *tail = head;
    if (head == NULL) {
        return 3;
    }
    head->prev = NULL;
    head->next = NULL;
    head->text = strdup(word);
    if (head->text == NULL) {
        return 4;
    }

    // create linked list
    struct node_t *cur_node = head;
    while ((word = strtok(NULL, " ")) != NULL) {
        cur_node->next = malloc(sizeof(struct node_t));
        if (cur_node->next == NULL) {
            return 5;
        }

        cur_node->next->prev = cur_node;
        cur_node->next->next = NULL;
        cur_node->next->text = strdup(word);
        if (cur_node->next->text == NULL) {
            return 6;
        }

        cur_node = cur_node->next;
        tail = cur_node;
    }

    // prepare empty string
    char *rev_line;
    int rev_line_len = 0; // does not include string terminator

    rev_line = malloc(rev_line_len + 1);
    if (rev_line == NULL) {
        return 8;
    }
    rev_line[0] = '\0';

    // reversing by words
    cur_node = tail;
    int space_len = 0; // first word is without space
    while (cur_node) {
        rev_line_len += strlen(cur_node->text) + space_len;
        rev_line = realloc(rev_line, rev_line_len + 1);
        if (rev_line == NULL) {
            return 7;
        }

        if (space_len == 1) {
            strcat(rev_line, " ");
        }
        strcat(rev_line, cur_node->text);

        struct node_t *free_node = cur_node;
        cur_node = cur_node->prev;

        free(free_node->text);
        free(free_node);

        space_len = 1;
    }

    if (strcmp(rev_line, MSG) == 0) {
        return 0;
    }

    return 9;
}
