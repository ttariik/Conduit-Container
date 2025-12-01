// Load API URL from runtime config (injected by Docker)
declare const window: any;

export const environment = {
  production: true,
  api_url: (window._env && window._env.apiUrl) || 'http://localhost:8000/api'
};

