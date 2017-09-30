###
app_info = {
    name: 'Actionhero',
    build_type: 'compose',
    type_info: {
        compose_verison: '2',
        version_hash: 'dfhh35hgvt4ebv4',
        github_link: 'fdfhf'
    },
    source: {
        type: 'apphub',
        github_user: "actionhero",
        url_path: "actionhero",
    },
    metrics: {
        "ram": 2000.00,
        "disk": 5000.00
    }
}

app_info(app_info)


###
attributes = {
    haproxy: {
        "STATS_AUTH": {
            "name": "STATS_AUTH",
            "description": "STATS_AUTH",
            "default_value": "actionhero:actionhero",
            "mandatory": 1,
            "basic": 1,
            "editable": 1,
            "visible": 1,
            "type": 'env'
        },
        "STATS_PORT": {
            "name": "STATS_PORT",
            "description": "STATS_PORT",
            "default_value": 1936,
            "mandatory": 1,
            "basic": 1,
            "editable": 1,
            "visible": 1,
            "type": 'env'
        },
        "MONITOR_URI": {
            "name": "MONITOR_URI",
            "description": "MONITOR_URI",
            "default_value": "/api/status",
            "mandatory": 1,
            "basic": 1,
            "editable": 1,
            "visible": 1,
            "type": 'env'
        }
    },
    redis: {
    },
    actionhero: {
        "TCP_PORTS": {
            "name": "TCP_PORTS",
            "description": "TCP_PORTS",
            "default_value": 80805000,
            "mandatory": 1,
            "basic": 1,
            "editable": 1,
            "visible": 1,
            "type": 'env'
        },
        "ENABLE_TCP_SERVER": {
            "name": "ENABLE_TCP_SERVER",
            "description": "ENABLE_TCP_SERVER",
            "default_value": "true",
            "mandatory": 1,
            "basic": 1,
            "editable": 1,
            "visible": 1,
            "type": 'env'
        },
        "REDIS_HOST": {
            "name": "REDIS_HOST",
            "description": "REDIS_HOST",
            "default_value": "redis",
            "mandatory": 1,
            "basic": 1,
            "editable": 1,
            "visible": 1,
            "type": 'env'
        },
        "REDIS_PORT": {
            "name": "REDIS_PORT",
            "description": "REDIS_PORT",
            "default_value": 6379,
            "mandatory": 1,
            "basic": 1,
            "editable": 1,
            "visible": 1,
            "type": 'env'
        },
        "REDIS_DB": {
            "name": "REDIS_DB",
            "description": "REDIS_DB",
            "default_value": 0,
            "mandatory": 1,
            "basic": 1,
            "editable": 1,
            "visible": 1,
            "type": 'env'
        }
    }
}

attributes(attributes)


###
services = {
    "haproxy": {
        "haproxy_0": {
            "name": "haproxy_0",
            "protocol": "http",
            "port": "80"
        },
        "haproxy_1": {
            "name": "haproxy_1",
            "protocol": "",
            "port": "5000"
        },
        "haproxy_2": {
            "name": "haproxy_2",
            "protocol": "",
            "port": "1936"
        }
    },
    "redis": {
    },
    "actionhero": {
    }
}

services(services)


###
containers = {
    "haproxy": {
    },
    "redis": {
        build: {
            type: 'image',
            image: 'asdas'
        }
    },
    "actionhero": {
        command:'',
        build: {
            type: 'build',
            context:'asda',
            docekrfile:'Dockerfile'
        },
        depends_on: ['redis'],
        links: ''
        ### etc....
    }
}

containers(containers)