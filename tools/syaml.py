# simple yaml parser, only supports a single level of nesting and arrays that use the '-' notation
def parse(path) -> dict:
    obj = {}
    with open(path, 'r') as yaml:
        parent_key = None

        for line in yaml:
            if line.strip() == '' or line.lstrip().startswith('#'):  # ignore empty lines and comments
                continue

            if line.lstrip().startswith('-'):  # array item
                if not parent_key:
                    raise ValueError(f'array item found without parent key\n{line}')

                if parent_key not in obj:
                    obj[parent_key] = []

                item = line.split('-')[1].strip()

                if ':' in item:  # object array (ex: - name: value)
                    s_key, s_value = [s.strip() for s in item.split(':')]
                    # if the array is empty or the last item in the array already has the key, add a new item
                    if len(obj[parent_key]) == 0 or s_key in obj[parent_key][-1]:
                        obj[parent_key].append({})

                    obj[parent_key][-1][s_key] = s_value
                else:  # simple array (ex: - value)
                    obj[parent_key].append(item)

            elif ':' in line:  # key: value || key: { ... } || key: [ ... ]

                key, value = [s.strip() for s in line.split(':')]

                if line.replace(line.lstrip(), '') != '':  # key is indented (property of an object)

                    if not parent_key:
                        raise ValueError(f'line appears to be a property of an object but no key found in previous lines\n{line}')
                    if not value:
                        raise ValueError(f'line appears to be a property of an object but no value found\n{line}')

                    if parent_key not in obj:
                        obj[parent_key] = {}

                    if isinstance(obj[parent_key], list):
                        obj[parent_key][-1][key] = value
                    elif isinstance(obj[parent_key], dict):
                        obj[parent_key][key] = value

                elif not value:  # object or array, save the key for later
                    parent_key = key

                else:  # simple key/value pair
                    obj[key] = value
                    parent_key = None

            else:
                raise ValueError(f'line does not contain a colon or is misformatted\n{line}')

    return obj
