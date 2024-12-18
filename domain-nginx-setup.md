To set up domain-based access for **Prometheus**, **Grafana**, **Alertmanager**, and **Node Exporter**, while preserving your existing setup, follow this **step-by-step guide**:

---

### **1. Plan Subdomains**
You’ll create subdomains for these services. Here's an example:
- **Prometheus**: `prometheus.neyothetechguy.com.ng`
- **Grafana**: `grafana.neyothetechguy.com.ng`
- **Alertmanager**: `alertmanager.neyothetechguy.com.ng`
- **Node Exporter**: `nodeexporter.neyothetechguy.com.ng`

These subdomains will work alongside your existing domain (`neyothetechguy.com.ng` and `www.neyothetechguy.com.ng`) and Adminer.

---

### **2. Update DNS Records**
- Go to your Cloudflare DNS management page.
- Add **A records** for each subdomain pointing to your server’s public IP:
  | Subdomain           | Type | Name              | Content       | TTL   |
  |---------------------|------|-------------------|---------------|-------|
  | Prometheus          | A    | prometheus        | `54.229.9.22` | Auto  |
  | Grafana             | A    | grafana           | `54.229.9.22` | Auto  |
  | Alertmanager        | A    | alertmanager      | `54.229.9.22` | Auto  |
  | Node Exporter       | A    | nodeexporter      | `54.229.9.22` | Auto  |

**Verify DNS Propagation**: After adding these, use tools like [DNS Checker](https://dnschecker.org) to confirm the records are live.

---

### **3. Configure Nginx for Subdomains**
You will create **separate Nginx configurations** for each subdomain.

#### **Step 1: Create Configuration Files**
1. **Prometheus Configuration** (`/etc/nginx/sites-available/prometheus`)
   ```nginx
   server {
       listen 80;
       server_name prometheus.neyothetechguy.com.ng;

       location / {
           proxy_pass http://127.0.0.1:9090; # Prometheus default port
           proxy_set_header Host $host;
           proxy_set_header X-Real-IP $remote_addr;
           proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
           proxy_set_header X-Forwarded-Proto $scheme;
       }

       listen 443 ssl; # managed by Certbot
       ssl_certificate /etc/letsencrypt/live/neyothetechguy.com.ng/fullchain.pem; # managed by Certbot
       ssl_certificate_key /etc/letsencrypt/live/neyothetechguy.com.ng/privkey.pem; # managed by Certbot
       include /etc/letsencrypt/options-ssl-nginx.conf; # managed by Certbot
       ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem; # managed by Certbot
   }
   ```

2. **Grafana Configuration** (`/etc/nginx/sites-available/grafana`)
   ```nginx
   server {
       listen 80;
       server_name grafana.neyothetechguy.com.ng;

       location / {
           proxy_pass http://127.0.0.1:3000; # Grafana default port
           proxy_set_header Host $host;
           proxy_set_header X-Real-IP $remote_addr;
           proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
           proxy_set_header X-Forwarded-Proto $scheme;
       }

       listen 443 ssl; # managed by Certbot
       ssl_certificate /etc/letsencrypt/live/neyothetechguy.com.ng/fullchain.pem; # managed by Certbot
       ssl_certificate_key /etc/letsencrypt/live/neyothetechguy.com.ng/privkey.pem; # managed by Certbot
       include /etc/letsencrypt/options-ssl-nginx.conf; # managed by Certbot
       ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem; # managed by Certbot
   }
   ```

3. **Alertmanager Configuration** (`/etc/nginx/sites-available/alertmanager`)
   ```nginx
   server {
       listen 80;
       server_name alertmanager.neyothetechguy.com.ng;

       location / {
           proxy_pass http://127.0.0.1:9093; # Alertmanager default port
           proxy_set_header Host $host;
           proxy_set_header X-Real-IP $remote_addr;
           proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
           proxy_set_header X-Forwarded-Proto $scheme;
       }

       listen 443 ssl; # managed by Certbot
       ssl_certificate /etc/letsencrypt/live/neyothetechguy.com.ng/fullchain.pem; # managed by Certbot
       ssl_certificate_key /etc/letsencrypt/live/neyothetechguy.com.ng/privkey.pem; # managed by Certbot
       include /etc/letsencrypt/options-ssl-nginx.conf; # managed by Certbot
       ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem; # managed by Certbot
   }
   ```

4. **Node Exporter Configuration** (`/etc/nginx/sites-available/nodeexporter`)
   ```nginx
   server {
       listen 80;
       server_name nodeexporter.neyothetechguy.com.ng;

       location / {
           proxy_pass http://127.0.0.1:9100; # Node Exporter default port
           proxy_set_header Host $host;
           proxy_set_header X-Real-IP $remote_addr;
           proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
           proxy_set_header X-Forwarded-Proto $scheme;
       }

       listen 443 ssl; # managed by Certbot
       ssl_certificate /etc/letsencrypt/live/neyothetechguy.com.ng/fullchain.pem; # managed by Certbot
       ssl_certificate_key /etc/letsencrypt/live/neyothetechguy.com.ng/privkey.pem; # managed by Certbot
       include /etc/letsencrypt/options-ssl-nginx.conf; # managed by Certbot
       ssl_dhparam /etc/letsencrypt/ssl-dhparams.pem; # managed by Certbot
   }
   ```

#### **Step 2: Enable Configurations**
```bash
sudo ln -s /etc/nginx/sites-available/prometheus /etc/nginx/sites-enabled/
sudo ln -s /etc/nginx/sites-available/grafana /etc/nginx/sites-enabled/
sudo ln -s /etc/nginx/sites-available/alertmanager /etc/nginx/sites-enabled/
sudo ln -s /etc/nginx/sites-available/nodeexporter /etc/nginx/sites-enabled/
```

#### **Step 3: Restart Nginx**
```bash
sudo nginx -t && sudo systemctl restart nginx
```

---

### **4. Obtain SSL/TLS Certificates for Subdomains**
Run Certbot to generate certificates for all your subdomains:
```bash
sudo certbot --nginx -d prometheus.neyothetechguy.com.ng -d grafana.neyothetechguy.com.ng -d alertmanager.neyothetechguy.com.ng -d nodeexporter.neyothetechguy.com.ng
```

---

### **5. Access Services**
Now you can access the tools securely:
- **Prometheus**: `https://prometheus.neyothetechguy.com.ng`
- **Grafana**: `https://grafana.neyothetechguy.com.ng`
- **Alertmanager**: `https://alertmanager.neyothetechguy.com.ng`
- **Node Exporter**: `https://nodeexporter.neyothetechguy.com.ng`

---

### **6. Optional Enhancements**
1. **Authentication**:
   - Use basic authentication or OAuth to secure these endpoints from unauthorized access.

2. **Firewall Rules**:
   - Ensure your security group allows ports 80 and 443 for HTTPS access.

3. **Backup**:
   - Backup your Nginx configuration files and certificates regularly.

##########################################################################
##########################################################################
##########################################################################
##########################################################################
# EXPLANATION OF NGINX REVERSE PROXY 

Yes, in this case, **Nginx is serving as a reverse proxy** for your services like **Prometheus**, **Grafana**, **Alertmanager**, and **Node Exporter**.

---

### **What is a Reverse Proxy?**

A **reverse proxy** is a server that sits in front of one or more backend servers, forwarding client requests to those servers and sending the servers' responses back to the clients. 

In your case:
- **Nginx** receives client requests at your domain names (e.g., `prometheus.neyothetechguy.com.ng`) and forwards these requests to the appropriate service running on your server (e.g., Prometheus running at `http://127.0.0.1:9090`).
- This creates a seamless connection between your clients and backend services.

---

### **Purpose of a Reverse Proxy**

A reverse proxy provides several important benefits:

1. **Centralized Access**:
   - You can access multiple backend services using a single point of entry (your Nginx server).
   - Each service is mapped to a unique subdomain, improving organization.

2. **SSL/TLS Termination**:
   - Nginx handles HTTPS (SSL/TLS) encryption, offloading the burden of encryption from backend services.
   - Your backend services (e.g., Prometheus, Grafana) can run on plain HTTP, reducing their complexity.

3. **Load Balancing**:
   - For high-traffic applications, Nginx can distribute client requests across multiple backend servers to balance the load and ensure high availability.

4. **Security**:
   - Nginx protects backend services by hiding their direct access (e.g., `127.0.0.1:9090` for Prometheus) and filtering malicious requests.
   - Adding authentication (basic or OAuth) ensures only authorized users access sensitive services.

5. **Caching**:
   - Nginx can cache responses from backend services, reducing the load on your backend and improving performance for repeated requests.

6. **Customizable Routing**:
   - You can define specific rules for how requests are routed to different backend services, such as adding headers or restricting access by IP.

---

### **How a Reverse Proxy Works**

Here’s how Nginx operates as a reverse proxy in your setup:

1. **Client Makes Request**:
   - A client sends a request to a domain, e.g., `https://prometheus.neyothetechguy.com.ng`.

2. **Nginx Receives the Request**:
   - Nginx listens for the request on port 80 (HTTP) or port 443 (HTTPS).

3. **Request Routing**:
   - Nginx checks its configuration (e.g., `server_name prometheus.neyothetechguy.com.ng`) and determines that this request should be forwarded to `http://127.0.0.1:9090`.

4. **Forward Request**:
   - Nginx forwards the request to the backend service (Prometheus in this case).

5. **Backend Responds**:
   - Prometheus processes the request and sends a response back to Nginx.

6. **Nginx Sends Response to Client**:
   - Nginx forwards the backend response to the client, maintaining the original connection with the client.

---

### **Example Request Flow**

1. **Client Request**:  
   `GET https://prometheus.neyothetechguy.com.ng/metrics`

2. **Nginx Configuration**:
   ```nginx
   server {
       listen 80;
       server_name prometheus.neyothetechguy.com.ng;

       location / {
           proxy_pass http://127.0.0.1:9090; # Forward to Prometheus
       }
   }
   ```

3. **Backend Service**:  
   Nginx forwards the request to `http://127.0.0.1:9090/metrics`.

4. **Response**:  
   Prometheus generates a response, which Nginx sends back to the client.

---

Let me know if you’d like a deeper dive into any specific aspect of reverse proxies or Nginx configuration! 😊