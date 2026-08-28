#include <stdio.h>
#include <stdint.h>
#include <string.h>

static int parse_record(const uint8_t *data, size_t len)
{
    char name[16];

    if (len < 2)
        return -1;

    uint8_t name_len = data[0];

    /*
     * Intentional bug:
     * name_len is controlled by the input,
     * but name is only 16 bytes long.
     */
    memcpy(name, data + 1, name_len);

    name[15] = '\0';

    printf("name: %s\n", name);

    return 0;
}

int main(void)
{
    /*
     * First byte says:
     *
     *     copy 32 bytes
     *
     * But parse_record() only has a 16-byte buffer.
     */
    const uint8_t input[] = {
        32,
        'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A',
        'A', 'A', 'A', 'A', 'A', 'A', 'A', 'A',
        'B', 'B', 'B', 'B', 'B', 'B', 'B', 'B',
        'C', 'C', 'C', 'C', 'C', 'C', 'C', 'C'
    };

    return parse_record(input, sizeof(input));
}