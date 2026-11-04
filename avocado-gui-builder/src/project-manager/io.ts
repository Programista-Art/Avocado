/**
 * Project I/O + Tauri-ready filesystem abstraction.
 * In web mode uses download / file input; Tauri commands can replace these later.
 */
import type { ProjectModel } from '@/types';
import { PROJECT_FORMAT_VERSION } from '@/types';

export function exportProjectJson(project: ProjectModel): string {
  return JSON.stringify({ ...project, formatVersion: PROJECT_FORMAT_VERSION }, null, 2);
}

export function downloadText(filename: string, text: string) {
  const blob = new Blob([text], { type: 'text/plain;charset=utf-8' });
  const url = URL.createObjectURL(blob);
  const a = document.createElement('a');
  a.href = url;
  a.download = filename;
  a.click();
  URL.revokeObjectURL(url);
}

/** Filesystem abstraction — swap for Tauri invoke('write_file') later. */
export const fs = {
  async readText(): Promise<string | null> {
    return new Promise((resolve) => {
      const input = document.createElement('input');
      input.type = 'file';
      input.onchange = async () => {
        const f = input.files?.[0];
        resolve(f ? await f.text() : null);
      };
      input.oncancel = () => resolve(null);
      input.click();
    });
  },
  writeText(name: string, text: string) {
    downloadText(name, text);
  },
};
