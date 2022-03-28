module.exports = function override(config, env) {
    okv = {
        fallback: {
            path: require.resolve('path-browserify'),
            crypto: require.resolve('crypto-browserify'),
            stream: require.resolve('stream-browserify'),
            buffer: require.resolve('buffer'),
        },
    };

    if (!config.resolve) {
        config.resolve = okv;
    } else {
        config.resolve.fallback = {
            ...config.resolve.fallback,
            ...okv.fallback,
        };
    }

    return config;
};
