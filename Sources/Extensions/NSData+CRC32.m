#import "NSData+CRC32.h"

@implementation NSData (CRC32)

- (NSUInteger)crc32
{
    uint32_t *table = malloc(sizeof(uint32_t) * 256);
    uint32_t crc = 0xffffffff;
    uint8_t *bytes = (uint8_t *)[self bytes];
    
    for (uint32_t i=0; i<256; i++)
    {
        table[i] = i;
        for (int j=0; j<8; j++)
        {
            if (table[i] & 1)
                table[i] = (table[i] >>= 1) ^ 0xedb88320;
            else
                table[i] >>= 1;
        }
    }
    
    for (int i=0; i<self.length; i++)
        crc = (crc >> 8) ^ table[crc & 0xff ^ bytes[i]];
    
    crc ^= 0xffffffff;
    
    free(table);
    return crc;
}

@end