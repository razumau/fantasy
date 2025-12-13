import { extendTheme } from '@chakra-ui/react';
import { defineStyle, defineStyleConfig } from '@chakra-ui/react'

const underlined = defineStyle({
    textDecoration: 'underline',
})

export const linkTheme = defineStyleConfig({
    variants: { underlined },
    defaultProps: {
        variant: 'underlined',
    }
})
const overrides = {
    styles: {
        global: {
        },
    },
    components: {
        Link: linkTheme,
    },
};

export default extendTheme(overrides);
