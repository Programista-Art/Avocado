/** Project validation: names, hierarchy, types. */
import type { ProjectModel, ValidationIssue } from '@/types';
import { getComponentMeta } from '@/framework/metadata';

const IDENT_RE = /^[A-Za-z_][A-Za-z0-9_]*$/;

export function validateProject(project: ProjectModel): ValidationIssue[] {
  const issues: ValidationIssue[] = [];
  let n = 0;
  const push = (i: Omit<ValidationIssue, 'id'>) => issues.push({ ...i, id: `v${++n}` });

  for (const form of project.forms) {
    const names = new Map<string, number>();
    for (const c of form.components) {
      names.set(c.name, (names.get(c.name) ?? 0) + 1);

      if (!IDENT_RE.test(c.name)) {
        push({
          severity: 'error',
          message: `Invalid Pascal identifier "${c.name}"`,
          messagePl: `Nieprawidłowy identyfikator Pascal "${c.name}"`,
          componentId: c.id,
          formId: form.id,
        });
      }

      if (!getComponentMeta(c.typeId)) {
        push({
          severity: 'error',
          message: `Unsupported component type "${c.typeId}"`,
          messagePl: `Nieobsługiwany typ "${c.typeId}"`,
          componentId: c.id,
          formId: form.id,
        });
      }

      if (c.parentId && !form.components.some((p) => p.id === c.parentId)) {
        push({
          severity: 'error',
          message: `Parent not found for "${c.name}"`,
          messagePl: `Nie znaleziono rodzica dla "${c.name}"`,
          componentId: c.id,
          formId: form.id,
        });
      }
    }

    for (const [name, count] of names) {
      if (count > 1) {
        push({
          severity: 'error',
          message: `Duplicate component name "${name}"`,
          messagePl: `Zduplikowana nazwa "${name}"`,
          formId: form.id,
        });
      }
    }

    for (const [handler, code] of Object.entries(project.userCode)) {
      if (!IDENT_RE.test(handler)) {
        push({
          severity: 'warning',
          message: `Event handler name "${handler}" is not a valid identifier`,
          messagePl: `Nazwa handlera "${handler}" nie jest poprawnym identyfikatorem`,
        });
      }
      if (code.includes('TODO')) {
        push({
          severity: 'info',
          message: `Handler "${handler}" still contains TODO`,
          messagePl: `Handler "${handler}" zawiera TODO`,
        });
      }
    }
  }

  return issues;
}
