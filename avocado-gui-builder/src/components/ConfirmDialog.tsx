export function ConfirmDialog({
  title,
  message,
  okLabel,
  cancelLabel,
  onConfirm,
  onCancel,
}: {
  title: string;
  message: string;
  okLabel: string;
  cancelLabel: string;
  onConfirm: () => void;
  onCancel: () => void;
}) {
  return (
    <div className="modal-backdrop" onClick={onCancel}>
      <div className="modal" onClick={(e) => e.stopPropagation()}>
        <h3>
          <span>⚠️</span> {title}
        </h3>
        <p style={{ color: 'var(--text-dim)', lineHeight: 1.5 }}>{message}</p>
        <div className="actions">
          <button onClick={onCancel}>{cancelLabel}</button>
          <button className="danger primary" onClick={onConfirm} style={{ background: 'var(--danger)', border: 'none', color: '#fff' }}>
            {okLabel}
          </button>
        </div>
      </div>
    </div>
  );
}
