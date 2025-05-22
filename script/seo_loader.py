import happybase
from faker import Faker
import random
from datetime import datetime, timedelta
import time

faker = Faker()
connection = happybase.Connection('localhost')  # Inside container
table = connection.table('webpages')

domains = ["example.com", "test.org", "mysite.net", "demo.co", "page.info"]
status_codes = [200, 200, 200, 404, 500]
content_sizes = {'small': 512, 'medium': 2048, 'large': 8192}

def reverse_domain(domain):
    return '.'.join(reversed(domain.split('.')))

def random_slug():
    return faker.slug()

def random_html(size):
    if size == 'small':
        return faker.text(100)
    elif size == 'medium':
        return faker.text(500)
    else:
        return faker.text(1500)

rowkeys = []
for domain in domains:
    for _ in range(4):
        slug = random_slug()
        rowkey = f"{reverse_domain(domain)}:{slug}"
        rowkeys.append(rowkey)

# Insert 20 pages with multiple versions
for rowkey in rowkeys:
    base_time = int(time.time() * 1000)  # ms timestamp

    # Insert 2–3 versions of HTML
    for i in range(random.randint(2, 3)):
        version_time = base_time - i * 1000  # Offset to simulate older versions
        html = random_html(random.choice(['small', 'medium', 'large']))
        table.put(rowkey.encode(), {b'content:html': html.encode('utf-8')}, timestamp=version_time)

    # Insert single metadata row (no versioning for metadata)
    title = faker.sentence(nb_words=4)
    created_at = faker.date_between(start_date='-180d', end_date='today')
    last_modified = created_at + timedelta(days=random.randint(0, 30))
    status = random.choice(status_codes)
    size = content_sizes[random.choice(['small', 'medium', 'large'])]

    table.put(rowkey.encode(), {
        b'metadata:title': title.encode('utf-8'),
        b'metadata:status_code': str(status).encode('utf-8'),
        b'metadata:created_at': str(created_at).encode('utf-8'),
        b'metadata:last_modified': str(last_modified).encode('utf-8'),
        b'metadata:content_size': str(size).encode('utf-8')
    })

    # Add 2 versions of inlink and outlink with different timestamps
    for direction in ['inlinks', 'outlinks']:
        link1 = random.choice(rowkeys)
        link2 = random.choice([rk for rk in rowkeys if rk != link1])
        table.put(rowkey.encode(), {
            f"{direction}:{random.randint(1,99)}".encode(): link1.encode()
        }, timestamp=base_time)
        table.put(rowkey.encode(), {
            f"{direction}:{random.randint(1,99)}".encode(): link2.encode()
        }, timestamp=base_time - 1000)

    print(f"✅ Inserted versions for: {rowkey}")

connection.close()
print("🚀 Done inserting 20 web pages with multi-version content.")
