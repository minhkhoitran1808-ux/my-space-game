import { StrictMode } from 'react';
import { createRoot } from 'react-dom/client';
import { DemoScene } from './DemoScene';

createRoot(document.getElementById('root')!).render(
  <StrictMode>
    <DemoScene />
  </StrictMode>,
);
