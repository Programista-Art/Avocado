import { useAppStore } from '@/state/store';
import { t, type Lang } from '@/i18n';

export function ValidationPanel({ lang }: { lang: Lang }) {
  const validation = useAppStore((s) => s.validation);
  const select = useAppStore((s) => s.select);

  if (!validation.length) return <div className="empty">{t(lang, 'empty.noIssues')}</div>;

  return (
    <div>
      <div className="panel-header">{t(lang, 'validation.title')}</div>
      {validation.map((v) => (
        <div
          key={v.id}
          className={`validation-item ${v.severity}`}
          onClick={() => v.componentId && select([v.componentId])}
        >
          <div>
            <strong style={{ textTransform: 'uppercase', fontSize: 10 }}>{v.severity}</strong>
            <div>{lang === 'pl' ? v.messagePl : v.message}</div>
          </div>
        </div>
      ))}
    </div>
  );
}
