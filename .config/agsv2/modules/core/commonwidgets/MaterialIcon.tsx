import { LabelProps } from 'astal/gtk3/widget';

interface MaterialIconProps extends Omit<LabelProps, 'child'> {
    icon: string;
    size: string;
}

export function MaterialIcon({ icon, size, ...rest }: MaterialIconProps) {
    return <label
        className={`icon-material txt-${size}`}
        label={icon}
        {...rest}
    />;
}